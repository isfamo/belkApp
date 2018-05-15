class ChangeColumnSentToRrdToSentToWorkhorse < ActiveRecord::Migration[5.0]
  def change
    rename_column :sample_requests, :sent_to_rrd, :sent_to_workhorse
  end
end
