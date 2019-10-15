defmodule GraphQl.Resolvers.Repository do
  use GraphQl.Resolvers.Base, model: Core.Schema.Repository
  alias Core.Services.Repositories
  alias Core.Schema.{Installation}

  def query(_, _), do: Repository

  def list_repositories(%{publisher_id: pid} = args, _) when not is_nil(pid) do
    Repository.for_publisher(pid)
    |> Repository.ordered()
    |> paginate(args)
  end

  def list_repositories(args, %{context: %{current_user: user}}) do
    Repository.for_user(user.id)
    |> Repository.ordered()
    |> paginate(args)
  end

  def list_installations(args, %{context: %{current_user: user}}) do
    Installation.for_user(user.id)
    |> Installation.ordered()
    |> paginate(args)
  end

  def create_repository(%{attributes: attrs}, %{context: %{current_user: user}}),
    do: Repositories.create_repository(attrs, user)
end