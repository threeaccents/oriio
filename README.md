# Mahi

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mahi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mahi, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/mahi>.


# Chunk Uploader
 - A global process per upload using horde registry
 - an upload monitor
  - if a chunk isn't sent within a timeout period then the process is killed
  - If a process is killed then the monitor restarts it

client sends a request to tell the api we are going to initialize a chunk upload
 - the request contains the file name, chunk number, file size
 - the server responds with the upload id
 - the client then uses this upload id to send the chunks
 - once a client sends all the chunks it sends a final request to see if the upload was completed successfully
  - If it was the server returns the url to the uploaded file
  - if it was not the server returns the chunk numbers that it is missing.


