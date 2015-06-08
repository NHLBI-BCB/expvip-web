class AddGeneSetToGene < ActiveRecord::Migration
  def change
    add_reference :genes, :gene_set, index: true, foreign_key: true
  end
end
