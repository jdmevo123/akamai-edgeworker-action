<p align="center">
  <img alt="Akamai logo" width="400" height="400" src="https://www.eiseverywhere.com/file_uploads/8fca94ae15da82d17d76787b3e6a987a_logo_akamai-developer-experience-2-OL-RGB.png"/>
  <h3 align="center">GitHub Action to deploy Akamai Edgeworkers</h3>
  <p align="center">
    <img alt="GitHub license" src="https://badgen.net/github/license/jdmevo123/akamai-purge-action?cache=300&color=green"/>
  </p>
</p>

# Deploy Akamai Edgeworkers   

This action calls the Akamai Api's to deploy edgeworkers to the Akamai platform.

## Usage

All sensitive variables should be [set as encrypted secrets](https://help.github.com/en/articles/virtual-environments-for-github-actions#creating-and-using-secrets-encrypted-variables) in the action's configuration.

## Authentication

You need to declare a `EDGERC` secret in your repository containing the following structure :
```
[edgeworkers]
client_secret = your_client_secret
host = your_host
access_token = your_access_token
client_token = your_client_token
```
You can retrieve these from Akamai Control Center >> Identity Management >> API User.

## Inputs

### `edgeworkersName`
**Required**
Edgeworker name: Currently set to use repository name

### `network`
**Required**
Network:
- staging
- production
Defaults to staging

### `groupid`
**Required** 
Akamai groupid to assign new registrations to

## `workflow.yml` Example

Place in a `.yml` file such as this one in your `.github/workflows` folder. [Refer to the documentation on workflow YAML syntax here.](https://help.github.com/en/articles/workflow-syntax-for-github-actions)

```yaml
steps:
    - uses: actions/checkout@v1
    - name: Deploy Edgeworkers
      uses: jdmevo123/akamai-edgeworker-action@1.0
      env:
        EDGERC: ${{ secrets.EDGERC }}
        token: ${{ secrets.PAT_TOKEN }}
      with:
        edgeworkersName: ${{ github.event.repository.name }}
        network: 'staging'
        groupid: '12345' Akamai GroupID used for registering new edgeworkers
```
## License

This project is distributed under the [MIT license](LICENSE.md).
