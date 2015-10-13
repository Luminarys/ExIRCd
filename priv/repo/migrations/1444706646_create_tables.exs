defmodule Repo.CreateTables do 
  use Ecto.Migration           

  def up do
    create table(:users) do
      add :nick, :string
      add :email, :string
      add :password, :string
    end

    create table(:topics) do
      add :text, :string
      add :setter, :string
      timestamps
    end

    create table(:channels) do
      add :owner_id, :integer
      add :topic_id, :integer
    end
    create index(:channels, [:owner_id])
    create index(:channels, [:topic_id])

    create table(:chanbans) do
      add :mask, :string
      add :setter, :string
      add :channel_id, :integer
      timestamps
    end
    create index(:chanbans, [:channel_id])
  end

  def down do
    drop index(:channels, [:owner_id])
    drop index(:channels, [:topic_id])
    drop index(:chanbans, [:channel_id])
    drop table(:chanbans)
    drop table(:channels)
    drop table(:topics)
    drop table(:users)
  end
end
