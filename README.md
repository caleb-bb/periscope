# Periscope

## ABOUT 
Version 0.6+ works with Liveview 19. For Liveview 17 and earlier, use version 0.5.6. I'm not sure which version works with Liveview 18.

## ABOUT 

Introducing Periscope which is meant to save you time when working with LiveView.
(feel free to star the repo if you like it!)

Engineers waste a lot of time tracking down the module for the currently-loaded LiveView. I’ve seen people grab random chunks of HTML out of the inspect and soft-search VS Code for that chunk. I’ve also seen people looking at the URL, and then waste five minutes scrolling through the router just to figure out what module they’re on.

Periscope solves this problem. Import it in your `iex.exs` and spin up your app locally with `iex -S mix phx.server`. Then type which_liveview. Voila, you now know which liveview you’re on!

Another big waste of time is sticking IO.inspect into random places in a module just to view the socket. Periscope also solves this problem aswell, type `socket()` and hey presto, you can view the socket! The socket function returns a socket struct, so you can treat it as one. That means you can type socket.assign to see your current assigns.

Can’t find the assigns or socket you’re looking for, because the currently loaded page is in a component? No problem. `component_names/0` returns a list of all active components, making it easy to find your module. You can even type `assigns_for(YourAppWeb.SomeLiveView.SomeChildComponent)` and view all of the assigns for `SomeChildComponent`.

Finding the routes for a component can be a bear as well. `mix phx.routes` gives you routes and HTTP verbs, but not module names. Finding the routes to a module requires going to the router and scrolling through to piece together the route bit by bit. Periscope solves this problem as well: just type `paths_and_liveviews` and you’ll get a map where each key is a fully-qualified module name and each value is a list of routes to that module. Easy-peasy.

## Installation

Periscope can be installed by adding `periscope` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:periscope, "~> 0.6.0"}
  ]
end
```

You may also want to add it to your `iex.exs` by adding `import Periscope`. This ensures that Periscope will be available in your terminal when you run your app locally.

Docs can be found at <https://hexdocs.pm/periscope>.

