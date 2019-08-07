FROM microsoft/dotnet:2.2-sdk AS installer-env

COPY . /src/dotnet-function-app
RUN cd /src/dotnet-function-app && \
    mkdir -p /home/site/wwwroot && \
    dotnet publish *.csproj --output /home/site/wwwroot

FROM mcr.microsoft.com/azure-functions/dotnet:2.0
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server \
    && echo "root:Docker!" | chpasswd 

# Copy the sshd_config file to its new location
COPY sshd_config /etc/ssh/

# Copy init_container.sh to the /bin directory
COPY init_container.sh /bin/
# Run the chmod command to change permissions on above file in the /bin directory
RUN chmod 755 /bin/init_container.sh

COPY --from=installer-env ["/home/site/wwwroot", "/home/site/wwwroot"]

EXPOSE 80 2222

CMD ["/bin/init_container.sh"]
