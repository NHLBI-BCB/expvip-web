class GenesController < ApplicationController
  before_action :set_gene, only: [:show, :edit, :update, :destroy]


  def getGeneIds(genes)
    ids = Array.new
    missing = Array.new
    gene_set = GeneSet.find(session[:gene_set_id])
    genes.each do |g|  
      gene = Gene.find_by(:name=>g, :gene_set_id=>gene_set.id)
      gene = Gene.find_by(:gene=>g, :gene_set_id=>gene_set.id) unless  gene
      if gene
        ids << gene.id
      else
        missing << g
      end
    end
    raise "Genes not found: #{missing.join(",")}" if missing.size != 0
    return ids
  end

  #
  def forwardHeatmap
    genes = params[:genes_heatmap].split(/[,\s]+/).map { |e| e.strip }
    raise "Please select less than 50 genes" if genes.size > 50
    ids = getGeneIds(genes)
    raise "Plese select some genes for the heatmap" if ids.size == 0
    session[:genes] = ids.join(',')
    redirect_to action: "heatmap",  studies: params[:studies]
  end

  def forwardSearch
    gene_name = nil
    gene_name = params[:gene]
    gene_name = params[:query] if params[:query]
    gene_set = GeneSet.find(params[:gene_set_selector])
    @gene = findGeneName gene_name, gene_set 
    session[:gene] = @gene.name
    session[:gene_set_id] = gene_set.id
    redirect_to  action: "show", id: @gene.id, studies: params[:studies]
  end

  def forwardCompare
    gene_name = nil
    gene_name = params[:gene]
    gene_name = params[:query] if params[:query]

    gene_set = GeneSet.find(params[:gene_set_selector])
    session[:gene_set_id] = gene_set.id
    @gene = findGeneName(gene_name, gene_set)
    @compare =  findGeneName params[:compare], gene_set
    redirect_to  action: "show", id: @gene.id, studies: params[:studies], compare:  @compare.name  
  end

  def findGeneName(gene_name, gene_set)
    gene = Gene.find_by(:name=>gene_name, :gene_set_id=>gene_set.id)
    gene = Gene.find_by(:gene=>gene_name, :gene_set_id=>gene_set.id) unless  gene
    raise "Gene not found: #{gene_name} for #{gene_set.name} " unless gene
    return gene  
  end

  # GET /genes
  # GET /genes.json
  def forward
    #puts "Index: #{params}"
    #Rails.logger.info "In forward"
    #Rails.logger.info session[:genes] 
    #Rails.logger.info params

    session[:studies] = params[:studies] if  params[:studies] 

    begin
      case params[:submit] 
      when "Heatmap"
        forwardHeatmap 
      when "Search"
        forwardSearch
      when "Compare"
        forwardCompare
      else
        raise "Unknow redirect: #{params[:submit]}"
      end
    rescue Exception => e
      flash[:error] = e.to_s
      redirect_to :back
      return
    end
end

def autocomplete
    #puts "In autocomplete!"
    gene_set_id = session[:gene_set_id] 
    @genes = Gene.order(:name).where("name LIKE ? and gene_set_id = ?", "%#{params[:term]}%", gene_set_id).limit(20)

    respond_to do |format|
      format.html
      format.json { 
        render json: @genes.map(&:name)
      }
    end
  end

  def heatmap
    session[:studies] = params[:studies] if  params[:studies] 
    studies = session[:studies]
    genes = []
    genes = session[:genes] if  session[:genes] 
    genes = params[:genes] if params[:genes]

    @args = {studies: studies }.to_query
    respond_to do |format|
      format.html { render :heatmap }
    end
  end

  # GET /genes/1
  # GET /genes/1.json
  def show
    session[:studies] = params[:studies] if  params[:studies] 
    studies = session[:studies]
    compare = ""
    alert = ""

    if params[:compare]
      @compare =  Gene.find_by(:name=>params[:compare])
      @compare =  Gene.find_by(:gene=>params[:compare]) unless  @compare
      compare = @compare.name
    end

    @args = {studies: studies, compare: compare }.to_query
    #studies.each { |e|  @studies += "studies[]=#{e}\&" }
  end

  
  # DELETE /genes/1
  # DELETE /genes/1.json
  #def destroy
    #@gene.destroy
  #  respond_to do |format|
      #format.html { redirect_to genes_url, notice: 'Gene was successfully destroyed.' }
      #format.json { head :no_content }
  #  end
  #end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gene
      @gene = Gene.find(params[:id]) if numeric? params[:id]
      @gene = Gene.find_by(:name=>params[:gene]) unless @gene
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def gene_params
      params.require(:gene).permit(:name,:studies, :cdna, :possition, :gene, :transcript)
    end

    def numeric?(string)
    # `!!` converts parsed number to `true`
    !!Kernel.Float(string) 
  rescue TypeError, ArgumentError
    false
  end
end
