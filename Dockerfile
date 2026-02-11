# Use the official Python image as a base
FROM python:3.11.2

# Set environment variables for Spark and Java
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV SPARK_VERSION=4.1.1
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/home/spark
ENV PATH=$SPARK_HOME/bin:$PATH
ENV JAVA_VERSION=17

# Install necessary packages and dependencies
RUN apt-get update && apt-get install -y \
"openjdk-${JAVA_VERSION}-jre-headless" \
curl \
wget \
vim \
sudo \
whois \
ca-certificates-java \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Download and Unzip Spark
RUN SPARK_DOWNLOAD_URL="https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" \
&& wget --verbose -O apache-spark.tgz "${SPARK_DOWNLOAD_URL}" \
&& mkdir -p /home/spark \
&& tar -xf apache-spark.tgz -C /home/spark --strip-components=1 \
&& rm apache-spark.tgz

# Set up a non-root user
ARG USERNAME=sparkuser
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set ownership for Spark directories
RUN chown -R $USER_UID:$USER_GID ${SPARK_HOME}

# Create directories for logs and event logs
RUN mkdir -p ${SPARK_HOME}/logs \
&& mkdir -p ${SPARK_HOME}/event_logs \
&& chown -R $USER_UID:$USER_GID ${SPARK_HOME}/event_logs \
&& chown -R $USER_UID:$USER_GID ${SPARK_HOME}/logs

# Set up Spark configuration for logging and history server
RUN echo "spark.eventLog.enabled true" >> $SPARK_HOME/conf/spark-defaults.conf \
&& echo "spark.eventLog.dir file://${SPARK_HOME}/event_logs" >> $SPARK_HOME/conf/spark-defaults.conf \
&& echo "spark.history.fs.logDirectory file://${SPARK_HOME}/event_logs" >> $SPARK_HOME/conf/spark-defaults.conf

# Install Python packages for Jupyter and PySpark
RUN pip install --no-cache-dir jupyterlab findspark

# Add startup script
COPY entrypoint.sh $SPARK_HOME/entrypoint.sh
RUN chmod +x $SPARK_HOME/entrypoint.sh

# Switch to non-root user
USER $USERNAME

# Set workdir and create application directories
RUN mkdir -p /home/$USERNAME/app

WORKDIR /home/$USERNAME/app

# Expose necessary ports for Jupyter and Spark UI
EXPOSE 4040 4041 18080 8888

# Run startup script
ENTRYPOINT ["/home/spark/entrypoint.sh"]
