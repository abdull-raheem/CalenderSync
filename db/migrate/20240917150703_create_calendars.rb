class CreateCalendars < ActiveRecord::Migration[7.2]
  def change
    create_table :calendars do |t|
      t.references :user, null: false, foreign_key: true
      t.string :google_calendar_id
      t.string :name
      t.string :timezone

      t.timestamps
    end
    add_index :calendars, :google_calendar_id, unique: true
  end
end
