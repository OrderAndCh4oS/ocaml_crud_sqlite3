#!/bin/sh

function execute_and_time() {
  eval "$1 -w '\nTime elapsed: %{time_total} seconds'"
  echo ""  # Adding a new line for readability
}

function get_all_articles() {
  execute_and_time 'curl -v -i http://localhost:3000/blog'
}

function get_one_article() {
  ID=${1:-1}
  execute_and_time "curl -v -i http://localhost:3000/blog/${ID}"
}

function post_article() {
  DATA=${1:-'{"author":"Jane Doe", "content":"This is another new blog post!"}'}
  execute_and_time "curl -v -i -X POST -H 'Content-Type: application/json' -d '${DATA}' http://localhost:3000/blog"
}

function put_article() {
  ID=${1:-1}
  DATA=${2:-'{"author":"Jane Doe", "content":"This blog post has been updated"}'}
  execute_and_time "curl -v -i -X PUT -H 'Content-Type: application/json' -d '${DATA}' http://localhost:3000/blog/${ID}"
}

function delete_article() {
  ID=${1:-1}
  execute_and_time "curl -v -i -X DELETE http://localhost:3000/blog/${ID}"
}

function patch_article() {
  ID=${1:-1}
  DATA=${2:-'{"content":"This blog post content has been updated again"}'}
  execute_and_time "curl -v -i -X PATCH -H 'Content-Type: application/json' -d '${DATA}' http://localhost:3000/blog/${ID}"
}

"${@}"
