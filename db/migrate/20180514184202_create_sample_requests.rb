class CreateSampleRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :sample_requests do |t|
      t.string   "product_id"
      t.string   "color_id"
      t.date     "completed_at"
      t.datetime "created_at",             null: false
      t.datetime "updated_at",             null: false
      t.boolean  "sent_to_rrd"
      t.string   "of_or_sl"
      t.date     "turn_in_date"
      t.boolean  "silhouette_required"
      t.string   "instructions"
      t.string   "sample_type"
      t.string   "on_hand_or_from_vendor"
      t.string   "color_name"
      t.string   "return_to"
      t.string   "return_notes"
      t.boolean  "must_be_returned"

      t.timestamps
    end
  end
end
