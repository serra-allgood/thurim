use Amnesia

defdatabase Thurim.Database do
  deftable Globals, [:key, :value], type: :set do
    def current_count() do
      Amnesia.transaction do
        counter = read("counter")

        if is_nil(counter) do
          0
        else
          counter.value
        end
      end
    end

    def increment() do
      Amnesia.transaction do
        count = current_count()
        write(%Globals{key: "counter", value: count + 1})
      end
    end
  end
end
