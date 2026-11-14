<!-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> -->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Re-sign PR 70 with your own key

**Do not run these yet.** Wait until Claude says the finished branch (with the
Manifest) is pushed to `validation/issue-23-native-da`. That is after General
merges CompositionalDA, about 15 Nov. If you run them earlier, the later push
overwrites your signatures.

Run everything on your own computer, where your signing key
`~/.ssh/id_ed25519_signing` is.

## 1. One-time setup (skip any part you have already done)

Tell git to sign with your SSH signing key:

```bash
git config --global gpg.format ssh
```

```bash
git config --global user.signingkey ~/.ssh/id_ed25519_signing.pub
```

Let git check signatures locally, so the check in step 4 shows `G`:

```bash
echo "6759885+hyperpolymath@users.noreply.github.com $(cat ~/.ssh/id_ed25519_signing.pub)" >> ~/.ssh/allowed_signers
```

```bash
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

Make sure GitHub knows this key as a **signing** key. It must show the type
"signing", not only "authentication":

```bash
gh ssh-key list
```

If it is not listed as a signing key, add it:

```bash
gh ssh-key add ~/.ssh/id_ed25519_signing.pub --type signing
```

## 2. Get the branch

Go to your clone of the fork. If you have none, clone it first with
`git clone https://github.com/hyperpolymath/MetaManifold-WebUI.git`.

```bash
cd MetaManifold-WebUI
```

```bash
git fetch origin validation/issue-23-native-da
```

```bash
git fetch https://github.com/JoshuaJewell/MetaManifold-WebUI.git main:refs/remotes/upstream/main
```

```bash
git switch -C validation/issue-23-native-da origin/validation/issue-23-native-da
```

Use your noreply address as committer in this repository. It is already the
author address on the commits, and GitHub accepts it for Verified:

```bash
git config user.name "Jonathan D.A. Jewell"
```

```bash
git config user.email "6759885+hyperpolymath@users.noreply.github.com"
```

## 3. Re-sign every commit

This keeps the author, the messages and the content. It only adds your
signature. If your key has a passphrase, git asks for it once per commit
(3 times).

```bash
git rebase --exec 'git commit --amend --no-edit -S' upstream/main
```

## 4. Check before you push

Every line must start with a hash and then `G`. `N` means unsigned; `E` means
git could not check the signature:

```bash
git log --format='%h %G? %an | %s' upstream/main..HEAD
```

This must print nothing (no merge commits allowed):

```bash
git log --merges --oneline upstream/main..HEAD
```

This must print `0` (the branch is not behind Joshua's main):

```bash
git rev-list --count HEAD..upstream/main
```

If any check fails, stop and tell Claude what it printed.

## 5. Push

```bash
git push --force-with-lease origin validation/issue-23-native-da
```

## 6. Confirm on GitHub

1. Open https://github.com/JoshuaJewell/MetaManifold-WebUI/pull/70/commits.
2. Each commit must show a green **Verified** badge.
3. Tell Claude, who checks that CI is green before you mark the PR ready for
   review.
