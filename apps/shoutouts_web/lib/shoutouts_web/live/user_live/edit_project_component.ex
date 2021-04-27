defmodule ShoutoutsWeb.UserLive.EditProjectComponent do
  @moduledoc """
  Live component wrapping a Project form.
  """
  use ShoutoutsWeb, :live_component

  alias Shoutouts.Projects

  @impl true
  def update(%{project: project} = assigns, socket) do
    changeset = Projects.change_project(project)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"project" => project_params},
        %{assigns: %{project: project}} = socket
      ) do
    changeset = Projects.change_project(project, project_params)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"project" => project_params},
        %{assigns: %{project: project}} = socket
      ) do
    case Projects.update_project(project, project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> assign(:project, project)
         |> put_flash(:info, "Project updated successfully")
         # Workaround components having their own flash, the other option is to copy live.html.leex
         |> push_redirect(to: Routes.user_index_path(socket, :edit_project, project.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
