FROM public.ecr.aws/lambda/python:3.9

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install dependencies
RUN pip install -r requirements.txt

# Copy function code
COPY ml_prediction.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD [ "ml_prediction.handler" ]