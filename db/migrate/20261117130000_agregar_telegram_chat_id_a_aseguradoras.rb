class AgregarTelegramChatIdAAseguradoras < ActiveRecord::Migration[8.1]
  def change
    add_column :aseguradoras, :telegram_chat_id, :string
  end
end
