Unposted draft.
Its reply is in the past tense, but none of the package fixes it describes are done yet.

# CompositionalDA registration (JuliaRegistries/General#175952): fixes and reply

The General reviewer goerz blocked the automatic merge on 15 Nov. Do the
package fixes first, then post the reply, then re-trigger Registrator with the
same version (0.1.0).

## Package fixes (in hyperpolymath/CompositionalDA.jl, a session with push access)

1. README: remove or rewrite "Launch review remains pending" so it does not
   contradict a registration. Keep the honest scope (the ANCOM-BC calibration
   finding stays documented as a known limitation, not as a release hold).
2. `docs/LAUNCH-READINESS.adoc`: remove "Registration remains on hold", or
   record that registration was approved by the maintainer on a stated date.
3. GitHub repository description ("About"): remove "not yet registered".
4. Delete the git tags `v0.1.0` and `v0.2.0`. Add the TagBot workflow so the
   tag is created after registration.
5. Add coverage collection to CI (for example julia-actions/julia-processcoverage
   plus an upload), and a README example that runs `aldex2` and `ancombc` on a
   small table.
6. Commit with your own key, then comment `@JuliaRegistrator register` on the
   commit that has all of this.

## Reply to post on General#175952 (you post it; fill the bracket yourself)

> Thank you for the careful review.
>
> - The README, `docs/LAUNCH-READINESS.adoc` and the repository description no
>   longer say that registration is pending or on hold. The remaining text
>   describes a known limitation of ANCOM-BC in small unbalanced designs, which
>   is documented rather than hidden.
> - The `v0.1.0` and `v0.2.0` tags are deleted, and TagBot is set up.
> - CI now collects coverage, and the README has a short example for `aldex2`
>   and `ancombc`.
> - On the LLM policy: [IN YOUR OWN WORDS: that you, the maintainer, reviewed
>   the code yourself, when, and what you checked. Only write what is true.]
>
> I re-triggered Registrator on [COMMIT] with the same version.

Do not post the review sentence unless it is true in every detail.
