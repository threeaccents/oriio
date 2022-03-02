defmodule MahiWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use MahiWeb, :controller
      use MahiWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  @spec plug() :: Macro.t()
  def plug do
    quote do
      import Plug.Conn
      import Phoenix.Controller, only: [put_view: 2, render: 3]
      import MahiWeb.Gettext

      import ProperCase, only: [to_camel_case: 1]

      @behaviour Plug
    end
  end

  @spec controller() :: Macro.t()
  def controller do
    quote do
      use Phoenix.Controller, namespace: MahiWeb

      import Plug.Conn
      import MahiWeb.Gettext
      alias MahiWeb.Router.Helpers, as: Routes

      import ProperCase, only: [to_camel_case: 1]
    end
  end

  @spec view() :: Macro.t()
  def view do
    quote do
      use Phoenix.View,
        root: "lib/mahi_web/templates",
        namespace: MahiWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  @spec live_view() :: Macro.t()
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MahiWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  @spec live_component() :: Macro.t()
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  @spec component() :: Macro.t()
  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  @spec router() :: Macro.t()
  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  @spec channel() :: Macro.t()
  def channel do
    quote do
      use Phoenix.Channel
      import MahiWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import MahiWeb.ErrorHelpers
      import MahiWeb.Gettext
      alias MahiWeb.Router.Helpers, as: Routes

      import ProperCase, only: [to_camel_case: 1]
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
