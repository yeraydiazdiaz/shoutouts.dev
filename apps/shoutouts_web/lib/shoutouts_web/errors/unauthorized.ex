defmodule ShoutoutsWeb.ForbiddenError do
  defexception [:message, plug_status: 403]
end
