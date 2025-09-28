# MuMuDVB Deployment Script for GitHub
# Quick deployment to Ubuntu server

echo "🚀 Deploying MuMuDVB Web Panel to Ubuntu Server..."

# Create deployment package
cd /tmp
git clone https://github.com/braice/MuMuDVB.git mumudvb-deploy
cd mumudvb-deploy

# Run installation
chmod +x install-ubuntu.sh
./install-ubuntu.sh

echo "✅ Deployment complete!"
echo "Access web panel at: http://$(hostname -I | awk '{print $1}'):8080"