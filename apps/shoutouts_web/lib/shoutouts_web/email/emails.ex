defmodule ShoutoutsWeb.Email.Emails do
  use Bamboo.Phoenix, view: ShoutoutsWeb.EmailView

  require Logger

  alias ShoutoutsWeb.Email

  @default_sender "no-reply@shoutouts.dev"

  def send_shoutouts_digest() do
    shoutout_digest()
    |> Enum.each(
      fn {email, shoutouts} -> send_and_update_shoutouts(email, shoutouts) end)
  end

  @doc """
  Fetches shoutouts that need to be notified and returns a tuple with the
  email and the shoutouts that it covers and should be updated.
  """
  def shoutout_digest() do
    Shoutouts.Shoutouts.unnotified_shoutouts()
    |> Enum.group_by(&(&1.project.user))
    |> Enum.map(fn {project, shoutouts} ->
      {shoutout_digest_for_user(project, shoutouts), shoutouts}
    end)
  end

  @doc """
  Takes an owner and the shoutouts that need notifying and returns the email.
  """
  def shoutout_digest_for_user(%Shoutouts.Accounts.User{} = user, shoutouts) do
    user_names = (
      for s <- shoutouts, into: MapSet.new(), do: s.user.name)
      |> MapSet.to_list
    project_owner_names = shoutouts
      |> Enum.map(fn s -> {s.project.owner, s.project.name} end)
    new_email(
      to: user.email,
      from: @default_sender,
      subject: "New shoutouts for your projects"
    )
    |> put_html_layout({ShoutoutsWeb.LayoutView, "email.html"})
    |> assign(:first_name, Shoutouts.Accounts.first_name(user))
    |> assign(:user_names, user_names)
    |> assign(:project_owner_names, project_owner_names)
    |> render(:shoutouts_digest)
  end

  @doc """
  Sends an email and, if successful, updates the associated shoutouts's notified_at.

  Returns {:ok, response from the adapter} or {:error, error}.

  NOTE: we do not use deliver_later for now because we will be running this
  as part of our Quantum cron job weekly for now.
  """
  def send_and_update_shoutouts(email, shoutouts) do
    case Email.Mailer.deliver_now(email, response: true) do
      {:error, error} ->
        Logger.error("Error sending email")  # TODO: retry?
        {:error, error}
      {:ok, _email, response} ->
        Logger.info("Email sent successfully")
        shoutouts
        |> Enum.each(
          fn shoutout ->
            {:ok, _} = Shoutouts.Shoutouts.update_shoutout(shoutout, %{notified_at: DateTime.utc_now()})
          end)
        # TODO: we may want to wrap the above in a transaction
        {:ok, response}
    end
  end
end
