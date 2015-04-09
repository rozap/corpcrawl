defmodule Corpcrawl do
  alias Edgarex.Fetcher, as: Fetcher
  alias Edgarex.FTPStream, as: FTP
  alias Exquery.Query, as: Q
  
  @ignore_tokens ["&nbsp;", "&#160;", "\\*"]
  @headers ["Content-Type": "application/json", "Accept": "application/json"]


  def get_10ks(year, quarter) do
    Fetcher.form(year, quarter)
    |> Stream.filter(fn entry -> entry.form_type == "10-K" end)
  end

  defp load_ex221({form, file}) do
    ex221 = file
    |> Edgarex.Docparser.to_documents
    |> Enum.find(fn doc ->
      String.contains?(doc.type, "EX-21")
    end)

    {form, ex221}
  end


  def load_forms(forms_chunk) do
    forms_chunk
    |> Enum.map(fn form -> {form, Task.async(fn -> load_ex221(form) end)} end)
    |> Enum.map(fn {form, task} -> 
      try do
        Task.await(task, 60_000) 
      catch
        :exit, {:timeout, e} -> 
          IO.puts("Failure #{inspect e} for #{inspect form}")
          {:timeout, nil}
      end
    end)
    |> Enum.map(fn fm_doc -> Task.async(fn -> form_to_subs(fm_doc) end) end)
    |> Enum.map(fn task -> Task.await(task, 600_000) end)
    |> List.flatten

  end


  defp form_to_subs({form, nil}), do: []
  defp form_to_subs({form, doc}) do
    [doc] = doc
    |> List.wrap
    |> Edgarex.Docparser.doc_trees

    find_subsidiaries({form, doc})
  end


  defp clean_ugliness(els) do
    els
    |> Enum.map(fn {:text, contents, attrs} ->
      
      {:ok, re} = @ignore_tokens
      |> Enum.join("|")
      |> Regex.compile

      {:text, Regex.replace(re, contents, ""), attrs}
    end)
    |> Enum.filter(fn {_, c, _} ->
      c != ""
    end)
  end

  defp contents({:text, contents, _}), do: contents

  defp select(%{"sentences" => []}, _), do: ""

  defp select(dec, named_ent) do
    dec
    |> Dict.get("sentences", %{})
    |> List.first
    |> Dict.get("words", [])
    |> Enum.filter(fn [word, class] ->
      class["NamedEntityTag"] == named_ent
    end)
    |> Enum.map(fn [word, _] -> word end)
    |> Enum.join(" ")
  end

  defp nlp(text) do
    HTTPotion.start
    js = Poison.Encoder.encode(%{text: text}, [])
    try do
      %HTTPotion.Response{body: body} = r = HTTPotion.post "http://localhost:5000", [body: js, headers: @headers]

      if HTTPotion.Response.success?(r) do
        dec = Poison.decode!(body)

        loc = select(dec, "LOCATION")
        if loc != "" do
          org = text
          |> String.replace(loc, "")
          |> String.replace("()", "")
          |> String.strip
          |> String.strip(?,)

          %{name: org, location: loc}
        else 
          %{name: text}
        end
      else
        %{name: text}
      end
    rescue 
      e -> 
        IO.inspect(e)
        %{}

    end
  end

  defp row_to_dict(r) do
    d = r
    |> Enum.map(&(contents &1))
    |> Enum.join(", ")
    |> nlp

    d
  end

  defp remove_empty(results) do
    Enum.filter(results, fn res ->
      res
      |> Dict.values 
      |> Enum.join("") != ""
    end)
  end

  defp extract_meta(rows, :tr) do
    Enum.map(rows, &(row_to_dict &1))
  end

  defp extract_meta(enumerated, :p) do
    Enum.map(enumerated, fn {:text, name, _} ->
      %{name: name}
    end)
  end

  defp extract_text(enumerated, :tr) do
    enumerated
    |> Enum.map(fn row ->
      row
      |> List.wrap
      |> Q.all({:tag, "td", []})
      |> Enum.map(fn td ->
        td
        |> List.wrap
        |> Q.all({:text, :any, []})
        |> clean_ugliness
      end)
      |> List.flatten
    end)
    |> extract_meta(:tr)
  end

  defp extract_text(enumerated, kind) do
    enumerated
    |> Enum.map(fn row ->
      row
      |> List.wrap
      |> Q.all({:text, :any, []})
      |> clean_ugliness
    end)
    |> List.flatten
    |> extract_meta(kind)
  end

  defp find_enumerated(doc) do
    trs = Q.all(doc.tree, {:tag, "tr", []})
    if(length(trs) > 1) do
      extract_text(trs, :tr)
    else
      ps = Q.all(doc.tree, {:tag, "p",  []})
      extract_text(ps, :p)
    end
    |> remove_empty
  end


  def find_subsidiaries({form, doc}) do
    subs = find_enumerated(doc)
    # IO.puts "Company #{form.company_name}"
    # Enum.each(subs, fn s ->
    #   IO.puts "    - #{inspect s}"
    # end)
    {form, subs}
  end

end
