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

  MutSig.claim MutSig.mutation_type_dictionary_file_ext, :proc do
    new =<<-EOF
downstream_gene_variant noncoding
upstream_gene_variant noncoding
intergenic_variant noncoding
intron_variant noncoding
3_prime_UTR_variant silent
5_prime_UTR_variant silent
coding_sequence_variant silent
synonymous_variant silent
missense_variant nonsilent
incomplete_terminal_codon_variant silent
inframe_insertion nonsilent
non_coding_transcript_exon_variant noncoding
splice_acceptor_variant null
splice_donor_variant null
splice_region_variant null
frameshift_variant null
start_lost null
stop_gained null
stop_lost null
transcript_ablation null
EOF

    MutSig.mutation_type_dictionary_file.read.chomp << "\n" << new.gsub(" ","\t")
  end
end
