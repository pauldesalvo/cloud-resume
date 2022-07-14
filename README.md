# cloud-resume

| Challenge name | Cloud(s) | Challenge goal | 
| :--- | :--- | :--- | 
| The Cloud Resume Challenge | AWS | Create a portfolio site that shows off your cloud and DevOps skills." | 


## 1. HTML

Resume needs to be written in [HTML](https://developer.mozilla.org/en-US/docs/Web/HTML). Not a Word doc, not a PDF. 

## 2. CSS
Resume needs to be styled with [CSS]

## 3. Static Website
HTML resume should be deployed online as an [Amazon S3 static website](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html). 

## 4. HTTPS
The S3 website URL should use [HTTPS](https://www.cloudflare.com/learning/ssl/what-is-https/) for security. Need to use [Amazon CloudFront](https://aws.amazon.com/blogs/networking-and-content-delivery/amazon-s3-amazon-cloudfront-a-match-made-in-the-cloud/) to help with this.

## 5. DNS
Point a custom DNS domain name to the CloudFront distribution, so the resume can be accessed at something like `pauldesalvo.net`. Use [Amazon Route 53](https://aws.amazon.com/route53/) or any other DNS provider.

## 6. Javascript
Resume webpage should include a visitor counter that displays how many people have accessed the site. You will need to write a bit of Javascript to make this happen. 

## 7. Database
The visitor counter will need to retrieve and update its count in a database somewhere. Use Amazon's [DynamoDB](https://aws.amazon.com/dynamodb/) for this. 

## 8. API
Do not communicate directly with DynamoDB from Javascript code. Instead, create an [API](https://medium.com/@perrysetgo/what-exactly-is-an-api-69f36968a41f) that accepts requests from web app and communicates with the database. 

## 9. Python
Write a bit of code in the Lambda function, but it would be better for learning purposes to explore Python and its [boto3 library for AWS](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html). 

## 10. Tests
Include some tests for Python code. [Here are some resources](https://realpython.com/python-testing/) on writing good Python tests.

## 11. Infrastructure as Code
Don't configure API resources -- the DynamoDB table, the API Gateway, the Lambda function -- manually, by clicking around in the AWS console. Instead, define them  as code with Terraform.

## 12. Source Control
Don't want to be updating either back-end API or  front-end website by making calls from laptop, though. I want them to update automatically whenever making a change to the code. [continuous integration and deployment, or CI/CD](https://help.github.com/en/actions/building-and-testing-code-with-continuous-integration/about-continuous-integration).) Create a [GitHub repository](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-new-repository) for your backend code. 

## 13. CI/CD (Back end)
Set up [GitHub Actions](https://help.github.com/en/actions/getting-started-with-github-actions/about-github-actions).

## 14. CI/CD (Front end)
Create a second GitHub repository for your website code. Create GitHub Actions such that when pushing new website code, the S3 bucket automatically gets updated.  

