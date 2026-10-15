FROM europe-west1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

#########################################################
# COMPILER AND OTHER LANGUAGE-SPECIFIC TOOLS            #
#########################################################
RUN curl -fsSL https://deb.nodesource.com/setup_24.x -o nodesource_setup.sh
RUN sudo bash nodesource_setup.sh
RUN sudo apt-get install -y nodejs


#########################################################
# CLI TOOLS                                             #
#########################################################

## Antigravity CLI (agy)
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin

# Terraform
ENV TERRAFORM_VERSION=1.16.4
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    sudo mv terraform /usr/local/bin

#########################################################
# REMOVAL OF UNWANTED EXTENSIONS AND TOOLS              #
#########################################################

# Remove Google Cloud Code, Gemini Code Assist (IDE extensions) and Gemini CLI from base image
RUN sudo npm uninstall -g @google/gemini-cli 2>/dev/null || true && \
    sudo rm -f /usr/bin/gemini && \
    sudo rm -rf /opt/code-oss/extensions/googlecloudtools.cloudcode \
                /opt/code-oss/extensions/google.geminicodeassist \
                /opt/code-oss/extensions/google.gemini-cli-vscode-ide-companion


#########################################################
# VSCode extensions                                     #
#########################################################

## Terraform
ENV TERRAFORM_EXT_VERSION=2.40.0
RUN wget https://open-vsx.org/api/hashicorp/terraform/linux-x64/${TERRAFORM_EXT_VERSION}/file/hashicorp.terraform-${TERRAFORM_EXT_VERSION}@linux-x64.vsix && \
    unzip hashicorp.terraform-${TERRAFORM_EXT_VERSION}@linux-x64.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/terraform

## Dockerfile
ENV DOCKER_EXT_VERSION=2.0.0
RUN wget https://open-vsx.org/api/ms-azuretools/vscode-docker/${DOCKER_EXT_VERSION}/file/ms-azuretools.vscode-docker-${DOCKER_EXT_VERSION}.vsix && \
    unzip ms-azuretools.vscode-docker-${DOCKER_EXT_VERSION}.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/docker

## Python
ENV PYTHON_EXT_VERSION=2026.4.0
RUN wget https://open-vsx.org/api/ms-python/python/${PYTHON_EXT_VERSION}/file/ms-python.python-${PYTHON_EXT_VERSION}.vsix && \
    unzip ms-python.python-${PYTHON_EXT_VERSION}.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/python

## Python debugger
ENV PYTHON_DEBUG_EXT_VERSION=2026.6.0
RUN wget https://open-vsx.org/api/ms-python/debugpy/linux-x64/${PYTHON_DEBUG_EXT_VERSION}/file/ms-python.debugpy-${PYTHON_DEBUG_EXT_VERSION}@linux-x64.vsix && \
    unzip ms-python.debugpy-${PYTHON_DEBUG_EXT_VERSION}@linux-x64.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/python-debugger

## SonarQube for IDE
ENV SONARQUBE_VERSION=5.10.0
RUN wget https://open-vsx.org/api/SonarSource/sonarlint-vscode/${SONARQUBE_VERSION}/file/SonarSource.sonarlint-vscode-${SONARQUBE_VERSION}.vsix && \
    unzip SonarSource.sonarlint-vscode-${SONARQUBE_VERSION}.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/sonarqube-for-ide

RUN chmod a+rwx -R /opt/code-oss/extensions


#########################################################
# USER PROFILE CUSTOMIZATION                            #
#########################################################

# Custom Antigravity statusline script (shows context filling & token counts)
COPY ./statusline.sh /usr/local/statusline.sh
RUN chmod +x /usr/local/statusline.sh

# Custom company banner and agy shell wrapper
COPY ./company-banner.sh /usr/local/bin/company-banner.sh
RUN chmod +x /usr/local/bin/company-banner.sh

COPY ./011_setup-agy-branding.sh /etc/profile.d/011_setup-agy-branding.sh
RUN chmod +x /etc/profile.d/011_setup-agy-branding.sh && \
    echo 'source /etc/profile.d/011_setup-agy-branding.sh' >> /etc/bash.bashrc

# Make sure Antigravity plugins and default settings are initialized at startup
COPY ./010_setup-antigravity-plugins.sh /etc/workstation-startup.d/
RUN chmod +x /etc/workstation-startup.d/010_setup-antigravity-plugins.sh

#########################################################
# IMAGE UPDATE                                          #
#########################################################

# Remove the broken Helm repository source list file to prevent the `apt update` failure.
RUN sudo rm -f /etc/apt/sources.list.d/helm-stable-debian.list
RUN sudo apt-get update -y && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

#########################################################
# LAST UPDATES                                          #
#########################################################

# Python installation
RUN sudo apt-get install -y --no-install-recommends --fix-missing \
        python3.13.5 \
        python3.13.5-venv \
        || true # ignore any error if it occurs