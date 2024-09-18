class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events do |t|
      t.references :calendar, null: false, foreign_key: true
      t.string :google_event_id
      t.string :title
      t.text :description
      t.datetime :start_time
      t.datetime :end_time
      t.string :location
      t.string :status

      t.timestamps
    end
    add_index :events, :google_event_id, unique: true
  end
end
