# OCaml CRUD Scratch Project

## Overview

This OCaml CRUD (Create, Read, Update, Delete) project is a simple web application that allows you to manage a blog's articles. It provides basic functionality to create, read, update, and delete articles stored in a SQLite database. The project is built using the Opium web framework and Lwt for asynchronous programming in OCaml.

## Features

1. **Create Articles**: You can add new articles to the blog by making a POST request to the `/blog` endpoint with a JSON payload containing the author and content of the article.

2. **Read Articles**: You can retrieve a list of all articles or fetch a specific article by its ID using GET requests to the `/blog` and `/blog/:id` endpoints, respectively.

3. **Update Articles**: Existing articles can be updated by sending a PUT request to the `/blog` endpoint with a JSON payload containing the updated author and content.

4. **Delete Articles**: You can delete an article by sending a DELETE request to the `/blog/:id` endpoint, where `:id` is the ID of the article you want to delete.

## Technologies Used

- **OCaml**: The primary programming language used for this project.
- **Opium**: A minimalistic web framework for building web applications in OCaml.
- **Lwt**: A library for writing asynchronous code in OCaml.
- **SQLite**: A lightweight and embedded database used for storing article data.

## Getting Started

To run this project, follow these steps:

1. Clone the repository to your local machine.
2. Install the required OCaml packages, Opium, Lwt, and SQLite3.
3. Build and run the project.

## Usage

- To create a new article, send a POST request to `/blog` with a JSON payload containing the article's author and content.
- To retrieve a list of all articles, make a GET request to `/blog`.
- To retrieve a specific article by its ID, make a GET request to `/blog/:id`, where `:id` is the article's ID.
- To update an existing article, send a PUT request to `/blog` with a JSON payload containing the updated author and content.
- To delete an article, send a DELETE request to `/blog/:id`, where `:id` is the article's ID.

