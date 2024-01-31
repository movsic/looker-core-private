## Port forward to establish RDP connection via localhost:8080 to the windows vm without external ip
gcloud compute start-iap-tunnel windows-looker-test 3389 \
    --local-host-port=localhost:8080 --project=${PROJECT_ID} \
    --zone=${ZONE}

## Setting up and testing a Git connection
To configure a LookML project with HTTPS Git authentication, follow these steps: 
    Turn on the Development Mode (toggle at the bottom of the left navigation panel)
    Select develop -> Projects
    Click "new lookml project"
    Choose name and then blank project
    Configure git

## Links
(Configure RDP)[https://cloud.google.com/compute/docs/instances/connecting-to-windows]
(Tunneling RDP connections)[https://cloud.google.com/iap/docs/using-tcp-forwarding#tunneling_rdp_connections]
(Setting up and testing a Git connection)[https://cloud.google.com/looker/docs/setting-up-git-connection]