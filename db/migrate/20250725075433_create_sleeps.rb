class CreateSleeps < ActiveRecord::Migration[7.1]
  def change
    create_table :sleeps do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :clock_in_time
      t.datetime :clock_out_time
      t.integer :duration_minutes

      t.timestamps
    end

    add_index :sleeps, :user_id, name: 'index_sleep_records_on_user_id'
    add_index :sleeps, :clock_in_time, name: 'index_sleep_records_on_clock_in_time'
    add_index :sleeps, :clock_out_time, name: 'index_sleep_records_on_clock_out_time'
    add_index :sleeps, [:user_id, :clock_in_time, :duration_minutes], name: 'index_sleep_records_on_user_id_clock_in_duration_minutes'
    add_index :sleeps, :user_id, unique: true, where: 'clock_out_time IS NULL', name: 'index_sleep_records_on_user_id_clock_out_time_null'
    add_index :sleeps, :duration_minutes, order: { duration_minutes: :desc }, where: 'clock_out_time IS NOT NULL', name: 'index_sleep_records_on_duration_minutes_partial'
  end
end
