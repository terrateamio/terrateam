type t = {
  dirspaceflow : Terrat_change.Dirspaceflow.t;
  when_modified : Terrat_repo_config.When_modified.t;
}
[@@deriving show]

(** Given a diff and configuration, determine the list of matches.  An optional
   [tag_query] can be specified to filter the responses.  The [filelist] is used
   to synthesize any directory entries that have globs in them.  The [filelist]
   is processed and any glob dirs that match.  The file is matched to the
   directory glob and then for matches the filename portion is cut off and a
   directory entry is synthesized.  Because [file_patterns] are always relative
   to the root, a special string variable can be used called [${DIR}] that will
   be replaced with the synthesized name.  For example:

   Given the configuration:

   {[
     dirs:
       _templates/**:
           when_modified:
               file_patterns: []
       aws/**/ec2/**/terragrunt.hcl:
           tags: ['ec2']
           when_modified:
               file_patterns: ['_templates/**/ec2/**/*.hcl', '${DIR}/*.hcl']
   ]}

   And a [filelist] of:

   - _templates/ec2/terragrunt.hcl
   - _templates/s3/terragrunt.hcl
   - aws/prod/ec2/us-east-1/terragrunt.hcl
   - aws/prod/ec2/us-west-1/terragrunt.hcl

   We will synthesize a [dirs] entry that looks like:

   {[
     dirs:
       _templates/ec2:
           when_modified:
               file_patterns: []
       _templates/s3:
           when_modified:
               file_patterns: []
       aws/prod/ec2/us-east-1:
           tags: ['ec2']
           when_modified:
               file_patterns: ['_templates/**/ec2/**/*.hcl', 'aws/prod/ec2/us-east-1/*.hcl']
       aws/prod/ec2/us-west-1:
           tags: ['ec2']
           when_modified:
               file_patterns: ['_templates/**/ec2/**/*.hcl', 'aws/prod/us-west-1/*.hcl']
   ]}
*)
val match_diff :
  ?tag_query:Terrat_tag_set.t ->
  filelist:string list ->
  Terrat_repo_config.Version_1.t ->
  Terrat_change.Diff.t list ->
  (t list, [> `Bad_glob of string ]) result

(** Given a list of dirspaces, map them to their directory in the repo config.
   If a dir path in the dirspace is not present in the repo config, it gets the
   default [When_modified] configuration.  If a directory is present but the
   workspace is not, it gets the default set of tags. *)
val map_dirspace :
  ?tag_query:Terrat_tag_set.t ->
  filelist:string list ->
  Terrat_repo_config.Version_1.t ->
  Terrat_change.Dirspace.t list ->
  t list

(** Merge a list with de-duplication.  Any duplicates are taken from the right
   list.  The order of the output list is unspecified. *)
val merge_dedup : t list -> t list -> t list

val dirspaceflow : t -> Terrat_change.Dirspaceflow.t
