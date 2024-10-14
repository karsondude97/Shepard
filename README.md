# Shepard

**Bring lost computers back into the environment**

The intent of Shepard is to automatically redploy the Jamf framework to a device with a functional APNS connection, but a borked Jamf binary connection. This automated deployment of the framework happens daily through Okta Workflows.

**Note: Redeploying the Jamf Framework to a device triggers an onboarding event and kicks off any onboarding processes.**

We find the devices with a broken binary connection via the following process:

1. Make a smart group of devices that have not checked in for more than 14 days.
2. Scope a Configuration Profile to this smart group of devices.
3. Devices that have installed the configuration profile are functional, communicating with your Jamf server via APNS. These devices likely have a broken Jamf binary connection.


## Okta Workflows Connectors Setup

Follow Okta's steps [here](https://help.okta.com/wf/en-us/content/topics/workflows/learn/about-workflowsconsole.htm) to access the Workflows console.

1. Add the [Jamf Pro Classic API Connector](https://help.okta.com/wf/en-us/content/topics/workflows/connector-reference/jamf/overviews/authorization.htm)

2. Add the Jamf Pro API Connector
- _The same steps as the Classic API Connector, but the connector is named differently_


## Setup

1. Download and run the [Shepard.sh](https://github.com/karsondude97/Shepard/blob/main/Shepard.sh) script. This script only needs to be run once, so it can be run locally from your device. The script:
    - Creates a Smart Group of devices that have not checked in for over 14 days.
    - Creates a Configuration Profile and scopes it to the above smart group (This profile just puts a plist on devices).
    - Outputs the IDs of the Smart Group and Configuration Profile. You'll need these for the Okta Workflows.
  
  - Before running the script, you will need to update 3 variables at the top of the script with information of your Jamf Pro Server:
      ```sh
      JAMF="https://{your_server}.jamfcloud.com"
      Username=""
      Password=""
      ```
    - The account you use here cannot be a SSO user.

2. Download the [shepard.folder](https://github.com/karsondude97/Shepard/blob/main/shepard.folder) file and install the template into your Workflows environment
3. Inside the folder you should see two flows. **_1 - Shepard (Add 2 IDs from Script)_** is the main flow that will trigger each day at 9 AM, calling the helper flow each time.
4. You will need to update 2 cards in the main **_1 - Shepard (Add 2 IDs from Script)_** flow. Update the first card with the Smart Group ID and the second with the Configuration Profile ID.
  - For the second Card, add the ID at the end of the path. For example, if the ID is 42, you would put the following in the card:
    ```
    /JSSResource/osxconfigurationprofiles/id/42
    ```

  <img width="1459" alt="Shepard" src="https://github.com/user-attachments/assets/01a389d9-7124-489b-ac16-7ac772dc59cb">


5. Establish the connections to the target apps inside all the flows
6. Enable all the flows
