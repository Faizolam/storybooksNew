PROJECT_ID=devopsstorybooks
ZONE=us-central1-a

run-local:
	docker-compose up


### Create gcs bucket to store tf backend
create-tf-backend-bucket:
	gsutil mb -p ${PROJECT_ID} gs://${PROJECT_ID}-terraform

### Here how we can use Secrets saved in google Secret Manager.
define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

# ### tstate file has choosen default workspace but we want to separate into staging and production environments so i'll go ahead and set it.
# ENV=staging  
# # Double ampersand(&&) combines the two into a single shell invocation beacause otherwise each command within make will be executed separately.
# # Invoking that make target will create the workspace and then we'll still need to re-initialize it as we did before

# check Environment 
check-env:
ifndef ENV
	$(error Please set ENV=[staging|prod])
endif

# This cannot be indented or else make will include spaces in front of secret
define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

###

terraform-create-workspace: check-env
	cd terraform && \
		terraform workspace new $(ENV)

terraform-init: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform init

TF_ACTION?=plan
terraform-action: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform $(TF_ACTION) \
		-var-file="./environments/common.tfvars" \
		-var-file="./environments/$(ENV)/config.tfvars" \
		-var="mongodbatlas_private_key=$(call get-secret,atlas_private_key)" \
		-var="atlas_uesr_password=$(call get-secret,atlas_user_password_$(ENV))" \
		-var="cloudflare_api_token=$(call get-secret,cloudflare_api_token)"

###SSH VM
SSH_STRING=fazza@storybooks-vm-$(ENV)
###GOOGLE_CLIENT_ID
OAUTH_CLIENT_ID=744129509211-9dnh669blj2i0citt36tlm7iv0kjn12n.apps.googleusercontent.com
# VERSION?=latest
GITHUB_SHA?=latest
LOCAL_TAG=storybooks-app:$(GITHUB_SHA)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)

CONTAINER_NAME=storybooks-api
DB_NAME=storybooks

ssh: check-env
	gcloud compute ssh $(SSH_STRING) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE)

ssh-cmd: check-env
	@gcloud compute ssh $(SSH_STRING) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE) \
		--command="$(CMD)"
# this make target is going to look nearly identical to the one above except it's going to take in this cmd environment variable so we can specify different ssh commands to execute rather than opening an interactive ssh session, this will send that one command and return the result for example if i execute this make target with command equal echo hello(make ssh-cmd CMD="echo hello") that will get executed on the virtual machine and i'll get the string hello back in my local terminal.
# ssh-cmd:
# 	@gcloud compute ssh $(SSH_STRING) \
# 		--project=$(PROJECT_ID) \
# 		--zone=$(ZONE) \
# 		--command="$(CMD)"


build:
	docker build -t $(LOCAL_TAG) .

push:
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)
# (-) skip this failer and execute continue for the next command.
# $(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'
deploy: check-env
	$(MAKE) ssh-cmd CMD='gcloud auth configure-docker'
	@echo "pulling new container image..."
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_TAG)'
	@echo "removing old container..."
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'
	@echo "starting new container..."
	@$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
			-e PORT=3000 \
			-e \"MONGO_URL=mongodb+srv://storybooks-user-$(ENV):$(call get-secret,atlas_user_password_$(ENV))@storybooks-$(ENV).ctkm5.mongodb.net/$(DB_NAME)?retryWrites=true&w=majority&appName=storybooks-staging\" \
			-e GOOGLE_CLIENT_ID=$(OAUTH_CLIENT_ID) \
			-e GOOGLE_CLIENT_SECRET=$(call get-secret,google_oauth_client_secret) \
			$(REMOTE_TAG) \
			'

# OAUTH_CLIENT_ID=744129509211-9dnh669blj2i0citt36tlm7iv0kjn12n.apps.googleusercontent.com

# GITHUB_SHA?=latest


# terraform-action:
#     @echo "Using environment: $(ENV)"
#     @echo "Common vars file: ./environments/common.tfvars"
#     @echo "Environment vars file: ./environments/$(ENV)/config.tfvars"
#     @cd terraform && \
#         terraform workspace select $(ENV) && \
#         terraform $(TF_ACTION) \
#         -var-file="./environments/common.tfvars" \
#         -var-file="./environments/$(ENV)/config.tfvars" \
#         -var="mongodbatlas_private_key=$(call get-secret,atlas_private_key)" \
#         -var="atlas_user_password=$(call get-secret,atlas_uesr_password_$(ENV))" \
#         -var="cloudflare_api_token=$(call get-secret,cloudflare_api_token)"