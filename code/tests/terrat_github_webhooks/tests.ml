let user_json =
  {|{
  "login": "octocat",
  "id": 1,
  "node_id": "MDQ6VXNlcjE=",
  "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4",
  "gravatar_id": "",
  "url": "https://api.github.com/users/octocat",
  "html_url": "https://github.com/octocat",
  "followers_url": "https://api.github.com/users/octocat/followers",
  "following_url": "https://api.github.com/users/octocat/following{/other_user}",
  "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
  "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
  "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
  "organizations_url": "https://api.github.com/users/octocat/orgs",
  "repos_url": "https://api.github.com/users/octocat/repos",
  "events_url": "https://api.github.com/users/octocat/events{/privacy}",
  "received_events_url": "https://api.github.com/users/octocat/received_events",
  "type": "User",
  "site_admin": false
}|}

let repo_json =
  Printf.sprintf
    {|{
  "id": 1296269,
  "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
  "name": "Hello-World",
  "full_name": "octocat/Hello-World",
  "private": false,
  "owner": %s,
  "html_url": "https://github.com/octocat/Hello-World",
  "description": "This your first repo!",
  "fork": false,
  "url": "https://api.github.com/repos/octocat/Hello-World",
  "forks_url": "https://api.github.com/repos/octocat/Hello-World/forks",
  "keys_url": "https://api.github.com/repos/octocat/Hello-World/keys{/key_id}",
  "collaborators_url": "https://api.github.com/repos/octocat/Hello-World/collaborators{/collaborator}",
  "teams_url": "https://api.github.com/repos/octocat/Hello-World/teams",
  "hooks_url": "https://api.github.com/repos/octocat/Hello-World/hooks",
  "issue_events_url": "https://api.github.com/repos/octocat/Hello-World/issues/events{/number}",
  "events_url": "https://api.github.com/repos/octocat/Hello-World/events",
  "assignees_url": "https://api.github.com/repos/octocat/Hello-World/assignees{/user}",
  "branches_url": "https://api.github.com/repos/octocat/Hello-World/branches{/branch}",
  "tags_url": "https://api.github.com/repos/octocat/Hello-World/tags",
  "blobs_url": "https://api.github.com/repos/octocat/Hello-World/git/blobs{/sha}",
  "git_tags_url": "https://api.github.com/repos/octocat/Hello-World/git/tags{/sha}",
  "git_refs_url": "https://api.github.com/repos/octocat/Hello-World/git/refs{/sha}",
  "trees_url": "https://api.github.com/repos/octocat/Hello-World/git/trees{/sha}",
  "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/{sha}",
  "languages_url": "https://api.github.com/repos/octocat/Hello-World/languages",
  "stargazers_url": "https://api.github.com/repos/octocat/Hello-World/stargazers",
  "contributors_url": "https://api.github.com/repos/octocat/Hello-World/contributors",
  "subscribers_url": "https://api.github.com/repos/octocat/Hello-World/subscribers",
  "subscription_url": "https://api.github.com/repos/octocat/Hello-World/subscription",
  "commits_url": "https://api.github.com/repos/octocat/Hello-World/commits{/sha}",
  "git_commits_url": "https://api.github.com/repos/octocat/Hello-World/git/commits{/sha}",
  "comments_url": "https://api.github.com/repos/octocat/Hello-World/comments{/number}",
  "issue_comment_url": "https://api.github.com/repos/octocat/Hello-World/issues/comments{/number}",
  "contents_url": "https://api.github.com/repos/octocat/Hello-World/contents/{+path}",
  "compare_url": "https://api.github.com/repos/octocat/Hello-World/compare/{base}...{head}",
  "merges_url": "https://api.github.com/repos/octocat/Hello-World/merges",
  "archive_url": "https://api.github.com/repos/octocat/Hello-World/{archive_format}{/ref}",
  "downloads_url": "https://api.github.com/repos/octocat/Hello-World/downloads",
  "issues_url": "https://api.github.com/repos/octocat/Hello-World/issues{/number}",
  "pulls_url": "https://api.github.com/repos/octocat/Hello-World/pulls{/number}",
  "milestones_url": "https://api.github.com/repos/octocat/Hello-World/milestones{/number}",
  "notifications_url": "https://api.github.com/repos/octocat/Hello-World/notifications{?since,all,participating}",
  "labels_url": "https://api.github.com/repos/octocat/Hello-World/labels{/name}",
  "releases_url": "https://api.github.com/repos/octocat/Hello-World/releases{/id}",
  "deployments_url": "https://api.github.com/repos/octocat/Hello-World/deployments",
  "created_at": "2011-01-26T19:01:12Z",
  "updated_at": "2011-01-26T19:14:43Z",
  "pushed_at": "2011-01-26T19:06:43Z",
  "git_url": "git://github.com/octocat/Hello-World.git",
  "ssh_url": "git@github.com:octocat/Hello-World.git",
  "clone_url": "https://github.com/octocat/Hello-World.git",
  "svn_url": "https://svn.github.com/octocat/Hello-World",
  "homepage": "https://github.com",
  "size": 180,
  "stargazers_count": 80,
  "watchers_count": 80,
  "language": "C",
  "has_issues": true,
  "has_projects": true,
  "has_downloads": true,
  "has_wiki": true,
  "has_pages": true,
  "forks_count": 9,
  "mirror_url": null,
  "archived": false,
  "open_issues_count": 0,
  "forks": 9,
  "open_issues": 0,
  "watchers": 80,
  "default_branch": "master",
  "is_template": false,
  "topics": [],
  "visibility": "public"
}|}
    user_json

let link href = Printf.sprintf {|{"href": "%s"}|} href

let links_json =
  Printf.sprintf
    {|{
  "self": %s,
  "html": %s,
  "issue": %s,
  "comments": %s,
  "review_comments": %s,
  "review_comment": %s,
  "commits": %s,
  "statuses": %s
}|}
    (link "https://api.github.com/repos/octocat/Hello-World/pulls/1")
    (link "https://github.com/octocat/Hello-World/pull/1")
    (link "https://api.github.com/repos/octocat/Hello-World/issues/1")
    (link "https://api.github.com/repos/octocat/Hello-World/issues/1/comments")
    (link "https://api.github.com/repos/octocat/Hello-World/pulls/1/comments")
    (link "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}")
    (link "https://api.github.com/repos/octocat/Hello-World/pulls/1/commits")
    (link "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f7")

let ref_json label ref_ sha =
  Printf.sprintf
    {|{
  "label": "%s",
  "ref": "%s",
  "sha": "%s",
  "user": %s,
  "repo": %s
}|}
    label
    ref_
    sha
    user_json
    repo_json

(* A pull_request.synchronize payload where GitHub sends null for fields that
   are still being computed (additions, deletions, changed_files, commits,
   comments, review_comments, mergeable_state, maintainer_can_modify). *)
let synchronize_with_nulls_json =
  Printf.sprintf
    {|{
  "action": "synchronize",
  "number": 1,
  "before": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0",
  "after": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  "pull_request": {
    "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1",
    "id": 1,
    "node_id": "PR_kwDOADYXqs4xxxxx",
    "html_url": "https://github.com/octocat/Hello-World/pull/1",
    "diff_url": "https://github.com/octocat/Hello-World/pull/1.diff",
    "patch_url": "https://github.com/octocat/Hello-World/pull/1.patch",
    "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1",
    "number": 1,
    "state": "open",
    "locked": false,
    "title": "Amazing new feature",
    "user": %s,
    "body": "Please pull in these awesome changes",
    "created_at": "2024-01-26T19:01:12Z",
    "updated_at": "2024-01-26T19:01:12Z",
    "closed_at": null,
    "merged_at": null,
    "merge_commit_sha": null,
    "assignees": [],
    "requested_reviewers": [],
    "requested_teams": [],
    "labels": [],
    "commits_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1/commits",
    "review_comments_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1/comments",
    "review_comment_url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}",
    "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1/comments",
    "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f7",
    "head": %s,
    "base": %s,
    "_links": %s,
    "author_association": "OWNER",
    "active_lock_reason": null,
    "draft": false,
    "merged": false,
    "mergeable": null,
    "rebaseable": null,
    "additions": null,
    "deletions": null,
    "changed_files": null,
    "commits": null,
    "comments": null,
    "review_comments": null,
    "mergeable_state": null,
    "maintainer_can_modify": null
  },
  "repository": %s,
  "installation": {
    "id": 12345,
    "node_id": "MDIzOkludGVncmF0aW9uMQ=="
  },
  "sender": %s
}|}
    user_json
    (ref_json "octocat:new-feature" "new-feature" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    (ref_json "octocat:master" "master" "e7e4f4d38f100ff01ee488e8ff77dd2b09f95eef")
    links_json
    repo_json
    user_json

(* Same payload but with the fields present (non-null) to verify normal parsing
   still works. *)
let synchronize_with_values_json =
  Printf.sprintf
    {|{
  "action": "synchronize",
  "number": 1,
  "before": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0",
  "after": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  "pull_request": {
    "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1",
    "id": 1,
    "node_id": "PR_kwDOADYXqs4xxxxx",
    "html_url": "https://github.com/octocat/Hello-World/pull/1",
    "diff_url": "https://github.com/octocat/Hello-World/pull/1.diff",
    "patch_url": "https://github.com/octocat/Hello-World/pull/1.patch",
    "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1",
    "number": 1,
    "state": "open",
    "locked": false,
    "title": "Amazing new feature",
    "user": %s,
    "body": "Please pull in these awesome changes",
    "created_at": "2024-01-26T19:01:12Z",
    "updated_at": "2024-01-26T19:01:12Z",
    "closed_at": null,
    "merged_at": null,
    "merge_commit_sha": null,
    "assignees": [],
    "requested_reviewers": [],
    "requested_teams": [],
    "labels": [],
    "commits_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1/commits",
    "review_comments_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1/comments",
    "review_comment_url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}",
    "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1/comments",
    "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f7",
    "head": %s,
    "base": %s,
    "_links": %s,
    "author_association": "OWNER",
    "active_lock_reason": null,
    "draft": false,
    "merged": false,
    "mergeable": true,
    "rebaseable": true,
    "additions": 10,
    "deletions": 5,
    "changed_files": 3,
    "commits": 2,
    "comments": 0,
    "review_comments": 0,
    "mergeable_state": "clean",
    "maintainer_can_modify": true
  },
  "repository": %s,
  "installation": {
    "id": 12345,
    "node_id": "MDIzOkludGVncmF0aW9uMQ=="
  },
  "sender": %s
}|}
    user_json
    (ref_json "octocat:new-feature" "new-feature" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    (ref_json "octocat:master" "master" "e7e4f4d38f100ff01ee488e8ff77dd2b09f95eef")
    links_json
    repo_json
    user_json

(* A pull_request.synchronize payload where the nullable fields are entirely
   absent from the JSON (not present at all, not even as null). *)
let synchronize_with_missing_fields_json =
  Printf.sprintf
    {|{
  "action": "synchronize",
  "number": 1,
  "before": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0",
  "after": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  "pull_request": {
    "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1",
    "id": 1,
    "node_id": "PR_kwDOADYXqs4xxxxx",
    "html_url": "https://github.com/octocat/Hello-World/pull/1",
    "diff_url": "https://github.com/octocat/Hello-World/pull/1.diff",
    "patch_url": "https://github.com/octocat/Hello-World/pull/1.patch",
    "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1",
    "number": 1,
    "state": "open",
    "locked": false,
    "title": "Amazing new feature",
    "user": %s,
    "body": "Please pull in these awesome changes",
    "created_at": "2024-01-26T19:01:12Z",
    "updated_at": "2024-01-26T19:01:12Z",
    "closed_at": null,
    "merged_at": null,
    "merge_commit_sha": null,
    "assignees": [],
    "requested_reviewers": [],
    "requested_teams": [],
    "labels": [],
    "commits_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1/commits",
    "review_comments_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1/comments",
    "review_comment_url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}",
    "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1/comments",
    "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f7",
    "head": %s,
    "base": %s,
    "_links": %s,
    "author_association": "OWNER",
    "active_lock_reason": null,
    "draft": false,
    "merged": false,
    "mergeable": null,
    "rebaseable": null
  },
  "repository": %s,
  "installation": {
    "id": 12345,
    "node_id": "MDIzOkludGVncmF0aW9uMQ=="
  },
  "sender": %s
}|}
    user_json
    (ref_json "octocat:new-feature" "new-feature" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    (ref_json "octocat:master" "master" "e7e4f4d38f100ff01ee488e8ff77dd2b09f95eef")
    links_json
    repo_json
    user_json

let parse_event data =
  let json = Yojson.Safe.from_string data in
  Terrat_github_webhooks.Event.of_yojson json

let test_synchronize_with_null_fields =
  Oth.test ~name:"Synchronize with null fields" (fun _ ->
      match parse_event synchronize_with_nulls_json with
      | Ok (Terrat_github_webhooks.Event.Pull_request_event _) -> ()
      | Ok _ -> assert false
      | Error err ->
          Printf.eprintf "Parse error: %s\n%!" err;
          assert false)

let test_synchronize_with_values =
  Oth.test ~name:"Synchronize with non-null fields" (fun _ ->
      match parse_event synchronize_with_values_json with
      | Ok (Terrat_github_webhooks.Event.Pull_request_event _) -> ()
      | Ok _ -> assert false
      | Error err ->
          Printf.eprintf "Parse error: %s\n%!" err;
          assert false)

let test_synchronize_with_missing_fields =
  Oth.test ~name:"Synchronize with missing fields" (fun _ ->
      match parse_event synchronize_with_missing_fields_json with
      | Ok (Terrat_github_webhooks.Event.Pull_request_event _) -> ()
      | Ok _ -> assert false
      | Error err ->
          Printf.eprintf "Parse error: %s\n%!" err;
          assert false)

let test =
  Oth.parallel
    [
      test_synchronize_with_null_fields;
      test_synchronize_with_values;
      test_synchronize_with_missing_fields;
    ]

let () =
  Random.self_init ();
  Oth.run test
