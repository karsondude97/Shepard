#!/bin/bash
#################################################
# Version: 1
# Author: Karson Fitzgerald
# Date: 2024/10/13
# Run at your own risk, I'm not responsible for issues this may or may not cause
#################################################

# Update the three variables boxed below with correct information
# Note, if this is your first time using the Jamf API, you can't use an SSO username and password for API calls

############################################
############# - Update - ###################
############################################
JAMF="https://{your_server}.jamfcloud.com"
Username=""
Password=""
############################################
############################################
############################################


bearerToken=""
tokenExpirationEpoch="0"

function getBearerToken() {
	response=$(curl -sku "$Username:$Password" "$JAMF/api/v1/auth/token" -X POST)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
	tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

function checkTokenExpiration() {
	nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
	if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
	then
		echo "Token valid until the following epoch time: " "$tokenExpirationEpoch"
	else
		#echo "No valid token available, getting new token"
		getBearerToken
	fi
}

function invalidateToken() {
	responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" $JAMF/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		#echo "Token successfully invalidated"
		bearerToken=""
		tokenExpirationEpoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
		echo "Token already invalid"
	else
		echo "An unknown error occurred invalidating the token"
	fi
}


checkTokenExpiration

smart_group_id=$(curl -sk -H "Authorization: Bearer ${bearerToken}" "$JAMF/JSSResource/computergroups/id/0" -H "content-type: text/xml" -X POST -d "<computer_group><name>Shepard: Check-In &gt; 14 Days</name><is_smart>true</is_smart><criteria><size>1</size><criterion><name>Last Check-in</name><priority>0</priority><and_or>and</and_or><search_type>more than x days ago</search_type><value>14</value><opening_paren>false</opening_paren><closing_paren>false</closing_paren></criterion></criteria></computer_group>" | xmllint --xpath 'computer_group/id/text()' -)

config_profile_id=$(curl -sk -H "Authorization: Bearer ${bearerToken}" "$JAMF/JSSResource/osxconfigurationprofiles/id/0" -H "content-type: text/xml" -X POST -d "<os_x_configuration_profile><general><name>Shepard - Redeploy Framework</name><description>This will be scoped to computers that haven't checked in for over 14 days. If they get this installed, APNS is still working and a framework redeployment can work.</description><distribution_method>Install Automatically</distribution_method><user_removable>false</user_removable><level>System</level><redeploy_on_update>Newly Assigned</redeploy_on_update><payloads>&lt;?xml version=\"1.0\" encoding=\"UTF-8\"?&gt;&lt;!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"&gt;&lt;plist version=\"1\"&gt;&lt;dict&gt;&lt;key&gt;PayloadUUID&lt;/key&gt;&lt;string&gt;0F55C73E-CD84-46BC-8A56-38664271EB49&lt;/string&gt;&lt;key&gt;PayloadType&lt;/key&gt;&lt;string&gt;Configuration&lt;/string&gt;&lt;key&gt;PayloadOrganization&lt;/key&gt;&lt;string&gt;Shepard&lt;/string&gt;&lt;key&gt;PayloadIdentifier&lt;/key&gt;&lt;string&gt;0F55C73E-CD84-46BC-8A56-38664271EB49&lt;/string&gt;&lt;key&gt;PayloadDisplayName&lt;/key&gt;&lt;string&gt;Shepard - Redeploy Framework&lt;/string&gt;&lt;key&gt;PayloadDescription&lt;/key&gt;&lt;string&gt;This will be scoped to computers that haven't checked in for over 14 days. If they get this installed, APNS is still working and a framework redeployment can work.&lt;/string&gt;&lt;key&gt;PayloadVersion&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;PayloadEnabled&lt;/key&gt;&lt;true/&gt;&lt;key&gt;PayloadRemovalDisallowed&lt;/key&gt;&lt;true/&gt;&lt;key&gt;PayloadScope&lt;/key&gt;&lt;string&gt;System&lt;/string&gt;&lt;key&gt;PayloadContent&lt;/key&gt;&lt;array&gt;&lt;dict&gt;&lt;key&gt;PayloadDisplayName&lt;/key&gt;&lt;string&gt;Custom Settings&lt;/string&gt;&lt;key&gt;PayloadIdentifier&lt;/key&gt;&lt;string&gt;ECA6FE39-2F14-480B-A41D-D17740EFC9EC&lt;/string&gt;&lt;key&gt;PayloadOrganization&lt;/key&gt;&lt;string&gt;JAMF Software&lt;/string&gt;&lt;key&gt;PayloadType&lt;/key&gt;&lt;string&gt;com.apple.ManagedClient.preferences&lt;/string&gt;&lt;key&gt;PayloadUUID&lt;/key&gt;&lt;string&gt;ECA6FE39-2F14-480B-A41D-D17740EFC9EC&lt;/string&gt;&lt;key&gt;PayloadVersion&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;PayloadContent&lt;/key&gt;&lt;dict&gt;&lt;key&gt;com.shepard.framework&lt;/key&gt;&lt;dict&gt;&lt;key&gt;Forced&lt;/key&gt;&lt;array&gt;&lt;dict&gt;&lt;key&gt;mcx_preference_settings&lt;/key&gt;&lt;dict&gt;&lt;key&gt;status&lt;/key&gt;&lt;string&gt;APNS is working&lt;/string&gt;&lt;/dict&gt;&lt;/dict&gt;&lt;/array&gt;&lt;/dict&gt;&lt;/dict&gt;&lt;/dict&gt;&lt;/array&gt;&lt;/dict&gt;&lt;/plist&gt;</payloads></general><scope><all_computers>false</all_computers><all_jss_users>false</all_jss_users><computer_groups><computer_group><id>$smart_group_id</id><name>Shepard: Check-In &gt; 14 Days</name></computer_group></computer_groups></scope><self_service><self_service_display_name>Redeploy Binary Check</self_service_display_name><install_button_text>Install</install_button_text><self_service_description/><force_users_to_view_description>false</force_users_to_view_description><security><removal_disallowed>Never</removal_disallowed></security><self_service_icon/><feature_on_main_page>false</feature_on_main_page><self_service_categories/><notification>false</notification><notification>Self Service</notification><notification_subject>Redeploy Binary Check</notification_subject><notification_message/></self_service></os_x_configuration_profile>" | xmllint --xpath 'os_x_configuration_profile/id/text()' -)

echo "Your smart group ID is: $smart_group_id"
echo "Your configuration profile ID is: $config_profile_id"

#Invalidate Token
trap invalidateToken EXIT