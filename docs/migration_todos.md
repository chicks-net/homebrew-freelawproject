# Org Migration TODO List

## Before or during move

- [ ] Disable Claude: remove github actions
- [ ] Disable Claude: remove API key from secrets
- [ ] Disable Claude: update `/.repo.toml`
- [ ] Update `/README` with new `brew tap` location
- [ ] Update `/justfile` test recipe with new `brew tap` location
- [ ] Update `.github/workflows/auto-assign.yml` if the maintainer has changed
- [ ] Update `.github/CODEOWNERS` if the maintainer has changed

## After moving verify

- [ ] Manual `brew install` still works
- [ ] Githb action "Brew Verify" still passes on all platforms
- [ ] issues are auto-assigned
- [ ] PRs are auto-assigned
- [ ] All github actions are passing
