open Logs
open Opium
open Lwt.Syntax
open Sqlite3

let db = Sqlite3.db_open "blog"

type article = { author : string; content : string } [@@deriving yojson]

type stored_article = { id : int64; author : string; content : string }
[@@deriving yojson]

let create_blog_table db =
  let sql =
    {|
        CREATE TABLE IF NOT EXISTS blog(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author TEXT NOT NULL,
        content TEXT NOT NULL);
      |}
  in
  match exec db sql with Rc.OK -> () | _ -> failwith "Error creating table"

let prep_rows stmt =
  let rec loop accum =
    let handle_row stmt accum =
      match
        ( Data.to_int64 (column stmt 0),
          Data.to_string (column stmt 1),
          Data.to_string (column stmt 2) )
      with
      | Some id, Some author, Some content ->
          let result = { id; author; content } in
          loop (result :: accum)
      | _ -> raise @@ Error "Invalid data, could not convert to required types"
    in
    match step stmt with
    | Rc.ROW -> handle_row stmt accum
    | Rc.DONE -> accum
    | _ -> raise @@ Error "Error querying data"
  in
  loop []

let select_article_list db =
  let sql = "SELECT id, author, content FROM blog" in
  let stmt = prepare db sql in
  prep_rows stmt

let select_article db id =
  let sql = "SELECT id, author, content FROM blog WHERE id=? LIMIT 1" in
  let stmt = prepare db sql in
  let idBind = bind stmt 1 @@ Data.INT id in
  match idBind with
  | Rc.OK -> prep_rows stmt
  | _ -> failwith "failed to bind parameter to the SQL query"

let insert_article db (article : article) =
  let stmt = prepare db "INSERT INTO blog (author, content) VALUES (?, ?)" in
  let authorBind = bind stmt 1 @@ Data.TEXT article.author in
  let contentBind = bind stmt 2 @@ Data.TEXT article.content in
  match (authorBind, contentBind) with
  | Rc.OK, Rc.OK -> (
      match step stmt with 
      | Rc.DONE -> let id = Sqlite3.last_insert_rowid db in
          id
      | _ -> failwith "Failed to insert")
  | _ -> failwith "Failed to bind parameters to the SQL query"

let update_article db id (article : article) =
  let stmt = prepare db "UPDATE blog SET author=?, content=? WHERE id=?" in
  let authorBind = bind stmt 1 @@ Data.TEXT article.author in
  let contentBind = bind stmt 2 @@ Data.TEXT article.content in
  let idBind = bind stmt 3 @@ Data.INT id in
  match (idBind, authorBind, contentBind) with
  | Rc.OK, Rc.OK, Rc.OK -> (
      match step stmt with Rc.DONE -> () | _ -> failwith "Failed to update")
  | _ -> failwith "Failed to bind parameters to the SQL query"

let delete_article db id =
  let stmt = prepare db "DELETE FROM blog WHERE id=?" in
  let idBind = bind stmt 1 @@ Data.INT id in
  match idBind with
  | Rc.OK -> (
      match step stmt with Rc.DONE -> () | _ -> failwith "Failed to delete")
  | _ -> failwith "Failed to bind parameter to the SQL query"

let get_article_list _ =
  let articles = select_article_list db in
  let json = [%to_yojson: stored_article list] articles in
  Logs.info (fun m -> m "Got all articles");
  Lwt.return (Response.of_json json)

let post_article request =
  let* body = Request.to_json_exn request in
  let article =
    match article_of_yojson body with
    | Ok article -> article
    | Error error -> raise (Invalid_argument error)
  in
  let id = insert_article db article in
  Logs.info (fun m -> m "Created article with ID %Ld" id);
  Lwt.return (Response.make ~status:`No_content ())

let put_article request =
  let* body = Request.to_json_exn request in
  let article =
    match article_of_yojson body with
    | Ok article -> article
    | Error error -> raise (Invalid_argument error)
  in
  let id = Router.param request "id" |> Int64.of_string in
  Logs.info (fun m -> m "Updating article with ID %Ld" id);
  update_article db id article;
  Lwt.return (Response.make ~status:`No_content ())

let delete_article request =
  let id = Router.param request "id" |> Int64.of_string in
  delete_article db id;
  Logs.info (fun m -> m "Deleted article with ID %Ld" id);
  Lwt.return (Response.make ~status:`No_content ())

let get_article request =
  let id = Router.param request "id" |> Int64.of_string in
  let article_list = select_article db id in
  match article_list with
  | hd :: _ ->
      let json = [%to_yojson: stored_article] hd in
      Logs.info (fun m -> m "Got article with ID %Ld" id);
      Lwt.return (Response.of_json json)
  | [] ->
          Logs.info (fun m -> m "Not found article with ID %Ld" id);
          Lwt.return (Response.make ~status:`Not_found ())

let error_logger_middleware handler req =
  Lwt.catch
    (fun () -> handler req)
    (fun ex ->
      err (fun msg -> msg "%s" (Printexc.to_string ex));
      Lwt.return 
      @@ Response.of_json ~status:`Internal_server_error 
      @@ Yojson.Safe.from_string {|{"error": "An internal server error occurred"}|}
    )

let () =
  Logs.set_reporter (Logs.format_reporter ());
  set_level (Some Info);
  create_blog_table db;
  App.empty
  |> App.middleware (Rock.Middleware.create ~filter:error_logger_middleware ~name:"Error Logger")
  |> App.get "/blog" get_article_list
  |> App.post "/blog" post_article
  |> App.put "/blog/:id" put_article
  |> App.delete "/blog/:id" delete_article
  |> App.get "/blog/:id" get_article
  |> App.run_command
