FROM python:3.10-slim-buster

# Set the working directory inside the container
WORKDIR /src

# Copy the project's requirements file into the container
COPY requirements.txt requirements.txt

# Install the Python dependencies
RUN pip install -r requirements.txt

# Copy all files from the "analytics" folder into the container
COPY analytics/ .

# Add an 'ls' command to list files in the /src directory and print the output
RUN ls && echo "Contents of /src directory listed above"

# Specify the command to run when the container starts
#CMD python app.py
ENTRYPOINT [ "python", "app.py" ] 
