defmodule ShoutoutsWeb.ProjectLive.FormComponent do
  @moduledoc """
  Live component wrapping a Shoutout form.
  """
  use ShoutoutsWeb, :live_component

  require Logger

  alias Shoutouts.Repo
  alias Shoutouts.Shoutouts.Shoutout
  alias Shoutouts.Shoutouts

  @impl true
  def update(%{project: project, current_user_id: current_user_id} = assigns, socket) do
    changeset =
      %Shoutout{text: "", user_id: current_user_id, project_id: project.id}
      |> Shoutouts.change_shoutout()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"shoutout" => params},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    changeset =
      changeset.data
      |> Shoutouts.change_shoutout(params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"shoutout" => params},
        %{assigns: %{project: project, changeset: changeset}} = socket
      ) do
    changeset = Shoutouts.change_shoutout(changeset.data, params)

    case Repo.insert(changeset) do
      {:ok, _shoutout} ->
        {:noreply,
         socket
         |> put_flash(:info, get_flash(project))
         |> push_redirect(
           to: Routes.project_show_path(socket, :show, project.owner, project.name)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Error on query", changeset.errors)

        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> put_flash(:error, "Error creating shoutout")}
    end
  end

  defp get_flash(project) do
    case project.pinned_only do
      true ->
        "Thanks! This project shows only a selection of shoutouts compiled by the owner. Don't worry, though, I'm sure they'll appreciate it."

      false ->
        "Shoutout added correctly. Thank you!"
    end
  end
end
