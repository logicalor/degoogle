require "fileinto";

#spam
if header "X-Spam-Flag" "YES" {
  fileinto "Junk";
  stop;
}

fileinto "INBOX";
