# Personal git identity, pulled in by [includeIf] rules in ~/.gitconfig
# for repos under personal locations (see run_onchange_after_10-git-identity.sh).
# Note: these emails already appear throughout this public repo's commit history,
# so there is nothing here that is not already public.
[user]
	name = Lauri Gates
	email = lauri.gates@gmail.com

# git send-email through Gmail, for mailing-list patches and reports from
# personal repos. Gmail needs an app password (2-Step Verification on); it is
# not stored here: send-email prompts on the first send and the osxkeychain
# credential helper keeps it.
[sendemail]
	smtpServer = smtp.gmail.com
	smtpServerPort = 587
	smtpEncryption = tls
	smtpUser = lauri.gates@gmail.com
	from = Lauri Gates <lauri.gates@gmail.com>
