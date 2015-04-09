defmodule Corpcrawl.Repo.Migrations.AddFilingsTable do
  use Ecto.Migration

  def up do
    create table(:company, primary_key: false) do
      add :name, :string, size: 2048
      add :cik, :integer, primary_key: true
    end

    create table(:filing) do
      add :form_type, :string
      add :date_filed, :string
      add :file_name, :string
      add :company_id, references(:company, column: :cik)
    end

    create table(:subsidiary) do
      add :name, :string, size: 2048
      add :location, :string, size: 2048
      add :filing_id, references(:filing)
    end
  end

  def down do
    drop table(:subsidiary)
    drop table(:filing)
    drop table(:company)
  end
end
