defmodule GraphQl do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  import GraphQl.Schema.Helpers

  import_types GraphQl.Schema.Types
  import_types GraphQl.Schema.Inputs

  alias GraphQl.Resolvers.{
    User,
    Chart,
    Repository
  }

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(User, User.data(ctx))
      |> Dataloader.add_source(Chart, Chart.data(ctx))
      |> Dataloader.add_source(Repository, Repository.data(ctx))

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  query do
    field :me, :user do
      middleware GraphQl.Middleware.Authenticated
      resolve fn _, %{context: %{current_user: user}} -> {:ok, user} end
    end

    field :publisher, :publisher do
      middleware GraphQl.Middleware.Authenticated
      resolve &User.resolve_publisher/2
    end

    connection field :users, node_type: :user do
      middleware GraphQl.Middleware.Authenticated
      resolve &User.list_users/2
    end

    connection field :publishers, node_type: :publisher do
      middleware GraphQl.Middleware.Authenticated
      resolve &User.list_publishers/2
    end

    connection field :repositories, node_type: :repository do
      middleware GraphQl.Middleware.Authenticated
      arg :publisher_id, :id

      resolve &Repository.list_repositories/2
    end

    connection field :installations, node_type: :installation do
      middleware GraphQl.Middleware.Authenticated

      resolve &Repository.list_installations/2
    end

    connection field :charts, node_type: :chart do
      middleware GraphQl.Middleware.Authenticated
      arg :repository_id, non_null(:id)

      resolve &Chart.list_charts/2
    end

    connection field :versions, node_type: :version do
      middleware GraphQl.Middleware.Authenticated
      arg :chart_id, non_null(:id)

      resolve &Chart.list_versions/2
    end
  end

  mutation do
    field :login, :user do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve safe_resolver(&User.login_user/2)
    end

    field :signup, :user do
      arg :attributes, non_null(:user_attributes)

      resolve safe_resolver(&User.signup_user/2)
    end

    field :create_publisher, :publisher do
      arg :attributes, non_null(:publisher_attributes)

      resolve safe_resolver(&User.create_publisher/2)
    end

    field :create_repository, :repository do
      arg :attributes, non_null(:repository_attributes)

      resolve safe_resolver(&Repository.create_repository/2)
    end
  end

  def safe_resolver(fun) do
    fn args, ctx ->
      try do
        case fun.(args, ctx) do
          {:ok, res} -> {:ok, res}
          {:error, %Ecto.Changeset{} = cs} -> {:error, resolve_changeset(cs)}
          error -> error
        end
      rescue
        error -> {:error, Exception.message(error)}
      end
    end
  end
end
