require 'rbbt-util'
require 'rbbt/resource'

module MutSig
  extend Resource
  self.subdir = 'share/databases/MutSig'

  #def self.organism(org="Hsa")
  #  Organism.default_code(org)
  #end

  #self.search_paths = {}
  #self.search_paths[:default] = :lib


  MutSig.claim MutSig.chr_files_hg19, :proc do |filename|
    url = 'http://www.broadinstitute.org/cancer/cga/sites/default/files/data/tools/mutsig/reference_files/chr_files_hg19.zip'
    TmpFile.with_file do |dir|
      FileUtils.mkdir_p dir
      
      if Rbbt.tmp["chr19.zip"].exists
        `(cd "#{dir}" && unzip "#{Rbbt.tmp["chr19.zip"].find}")`
      else
        zip_file = File.join(dir, "file.zip")
        `(cd "#{dir}" && wget "#{url}" -O "#{zip_file}" && unzip "#{zip_file}")`
        FileUtils.rm zip_file
      end
      
      FileUtils.mkdir_p filename
      `(cd "#{dir}" && mv chr_files_hg19/* "#{filename}")`
    end
    nil
  end

  MutSig.claim MutSig.mutation_type_dictionary_file, :url, "http://www.broadinstitute.org/cancer/cga/sites/default/files/data/tools/mutsig/reference_files/mutation_type_dictionary_file.txt"
  MutSig.claim MutSig.gene_covariates, :url, "http://www.broadinstitute.org/cancer/cga/sites/default/files/data/tools/mutsig/reference_files/gene.covariates.txt"
  MutSig.claim MutSig.exome_full192_coverage, :url, "http://www.broadinstitute.org/cancer/cga/sites/default/files/data/tools/mutsig/reference_files/exome_full192.coverage.zip"
end
