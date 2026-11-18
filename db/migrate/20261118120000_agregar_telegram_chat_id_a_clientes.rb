class AgregarTelegramChatIdAClientes < ActiveRecord::Migration[8.1]
  def change
    add_column :clientes, :telegram_chat_id, :string
  end
end
