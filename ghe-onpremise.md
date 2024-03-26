## GitHub application
To create a new Terrateam GitHub application against GHE using `docker-compose up setup` you also need to add the following environment variables to `docker-compose.yml`:
* `GHE_HOST`
* `GHE_PROTOCOL`

Here's what I have for the `setup` section:
```  setup:
    image: ghcr.io/terrateamio/terrateam-setup:latest
    environment:
      GH_ORG: "acme" # replace me
      GHE_HOST: "ghe.terrateam.io" # replace me
      GHE_PROTOCOL: "https"
    ports:
      - "3000:3000"
    networks:
      - terrateam
```

Make sure to save the `.env` file and the GitHub application URL.

## Terrateam Server env vars
After you create the Terrateam GitHub application against your GHE, then we'll need to add some environment variables to the Terrateam server. The environment variables that are required are:

```
GITHUB_API_BASE_URL=https://<ghe-endpoint>/api/v3
GITHUB_APP_URL=https://<ghe-endpoint>/github-apps/terrateam-io
GITHUB_WEB_BASE_URL=https://<ghe-endpoint>/
```

Replace `<ghe-endpoint>` with whatever your GHE endpoint is. I've been using Docker Compose so I have those environment variables defined in the `server` section of my `docker-compose.yml`.

## Start the Terrateam server
```
docker-compose up server
```

## Copy the Terrateam Action to your GHE instance

The code for the action must be available on your GitHub Enterprise instance.  To do this, mirror it.  Because it is just a git repository, mirroring can be done with the following operations performed on your local machine:

1. Create a repository for it on GHE, the repository might be in the organization `terrateam` organization with the repository name `action`.
2. `git clone git@github.com:terrateamio/action.git`
3. `git remote add ghe git@<ghe-host>:terrateam/action.git`
4. `git push ghe`

Replace `ghe-host` with the host of your GHE instance.  Not that the repository name `terrateam/action` can be whatever you want it to be, however it is referenced in the next step so be sure to use the name that you choose.


## Install Terrateam
Now that the Terrateam server is started you can go ahead and install the Terrateam GitHub application against your organization.

## Terrateam GitHub Action setup
1. Create a new repo in your organization
2. Enable access against the action repo https://docs.github.com/en/enterprise-server@3.10/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#allowing-access-to-components-in-an-internal-repository

## Configure your Terraform repository

Create your `.github/workflows/terrateam.yml` **note, replace the terrateam/action with where you pushed the action code**
```
name: 'Terrateam Workflow'
on:
  workflow_dispatch:
    inputs:
      # The work-token and api-base-url are automatically passed in by the Terrateam backend
      work-token:
        description: 'Work Token'
        required: true
      api-base-url:
        description: 'API Base URL'
jobs:
  terrateam:
    permissions: # Required to pass credentials to the Terrateam action
      id-token: write
      contents: read
    runs-on: self-hosted
    timeout-minutes: 1440
    name: Terrateam Action
    steps:
      - uses: actions/checkout@v3
      - name: Run Terrateam Action
        id: terrateam
        uses: terrateam/action@v1 # replace with your organization and repo. for example terrateamio/action@v1
        with:
          work-token: '${{ github.event.inputs.work-token }}'
          api-base-url: '${{ github.event.inputs.api-base-url }}'
        env:
          SECRETS_CONTEXT: ${{ toJson(secrets) }}
```

Add a Terrateam config to `.terrateam/config.yml`. We'll want to disable cost estimation for the proof of concept since this infrastructure isn't deployed. I can also instruct you on how to enable it by querying infracost.io directly.
```
cost_estimation:
  enabled: false
```
