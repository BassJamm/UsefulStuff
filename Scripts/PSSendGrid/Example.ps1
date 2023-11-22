$sendGridToken = "SG.tokenID"
$attachmentPath = $processInfo # File path to the attachment\data.
$attachmentDisposition = "attachment" # Value can either be "attachment" or "inline", inlines is for images, check the command help examples for info. 
$processInfo = Get-Process
try {
    
    # Basic email with just content.
    $Parameters = @{
        FromAddress             = "account@domain.com"
        ToAddress               = "account@domain.com"
        Subject                 = "SendGrid Test Email Example"
        Body                    = "Testing Email."
        AttachmentPath          = $attachmentPath
        AttachmentDisposition   = $attachmentDisposition
        Token                   = $sendGridToken
        FromName                = "Name of Account"
        ToName                  = "Name of recipient"
    }
    Send-PSSendGridMail @Parameters
} catch {
    $_
}
