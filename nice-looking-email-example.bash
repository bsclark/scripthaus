#!/bin/bash
#
# Note: email addresses can be just the address, or the 
# nicer "Formal Name <email@someplace.com>" format serperated by commas

sendTo="receiver@email.send.to"
sendCC="cc@email.send.to"
sendBCC="this.one@email.send.to, other@email.send.to"
fromAddr="Formal Name <email@someplace.com>"
mailSubject="Some Nice Soundig Subject"

emailMessage=$(cat <<'EM_EOF'
Some text
Some more test
Use backticks to include command output
echo variables as well
EM_EOF
)

mailFooter=$(cat <<'MF_EOF'
Thank you,
</pre>
</body>
</html>
MF_EOF
)

mailHeader=$(cat <<'MH_EOF'
<html>
<body>
<pre style="font: monospace">
MH_EOF
)

(
  echo "From: $fromAddr"
  echo "To: $sendTo"
  echo "CC: $sendCC"
  echo "BCC: $sendBCC"
  echo "Subject: $mailSubject"
  echo "MIME-Version: 1.0"
  echo "Content-Type: text/html"
  echo "Content-Disposition: inline"
  echo $mailHeader
  echo -e $emailMessage
  echo $mailFoooter
)| /usr/sbin/sendmail -t


#| /bin/mailx -s "$mailSubject" -c "$sendToCC" "$sendTo"
