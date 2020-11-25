# lac-topo-builder

Brand New Topology steps (Start over):

1) Use the AIR custom topology feature:
- Select `LAC` organization
- Click `Create a simulation` button in top left. The "Create A Simulation" dialog box will pop up
- Drop falconv2.dot or click `+` to upload file
- Drop-down the `Advanced` options
- Select a unique NetQ Username. Somthing like `lac-ci-base-simulation@example.com` it must be in an email format. The email does not need to exist
- Paste in the `cumulus-ztp` script from this repo in the `ZTP SCRIPT` box
- Paste in the `oob-mgmt-server-config-script.sh` from this repo in the `OOB-MGMT-SERVER CONFIG SCRIPT` box
- Click Submit

2) Wait for the simulation to load. Takes ~5-10 minutes for all nodes in the simulation to load. 

3) Reconfigure the netq-ts to match oob-network and production settings
- Once `netq-ts` node is loaded. Log in. Change password
- execute the script `netq-reconfigure.sh` from this repo on the netq-ts

4) Make any final changes to the base topology
5) Restore passwords on oob-mgmt and netq-ts using `passwd` command if desired

6) Click the "Add Users" button on the AIR UI inside of the simulation and add the user `lac-ci`. This allows the `lac-ci` service account permission to clone/duplicate this base simulation.

7) Click "Power off" on the AIR to store the simulation
8) Update the `BASE_SIMULATION` variable in the `cicd/scripts/duplicate-snapshots.py` script with the ID of this new base simulation. The simulation ID is in the URL of the simulation: 4baf18fb-adf9-4a34-a5d0-82b9b388eb9c:

https://air.cumulusnetworks.com/4baf18fb-adf9-4a34-a5d0-82b9b388eb9c/Simulation
