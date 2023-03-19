# Verifying the Tekton Pipelines Package Release

This package is published as an OCI artifact, signed with Sigstore [Cosign](https://docs.sigstore.dev/cosign/overview), and associated with a [SLSA Provenance](https://slsa.dev/provenance) attestation.

Using `cosign`, you can display the supply chain security related artifacts for the `ghcr.io/kadras-io/package-for-metrics-server` images. Use the specific digest you'd like to verify.

```shell
cosign tree ghcr.io/kadras-io/package-for-metrics-server
```

The result:

```shell
📦 Supply Chain Security Related artifacts for an image: ghcr.io/kadras-io/package-for-metrics-server
└── 💾 Attestations for an image tag: ghcr.io/kadras-io/package-for-metrics-server:sha256-57a109b45ad86ffd9f47f3626800fed777f94ba4fbb5eb1ca1a9a4286f66c9ed.att
   └── 🍒 sha256:55cbf5575b996f11aa5d5ead0eb862b9818fff38b96d8bfe1618df393c377d89
└── 🔐 Signatures for an image tag: ghcr.io/kadras-io/package-for-metrics-server:sha256-57a109b45ad86ffd9f47f3626800fed777f94ba4fbb5eb1ca1a9a4286f66c9ed.sig
   └── 🍒 sha256:7a74656a666a70f6e79274cec2aad64fdfc7af13e255fe85f50dadbebb688529
```

You can verify the signature and its claims:

```shell
cosign verify \
   --certificate-identity-regexp https://github.com/kadras-io \
   --certificate-oidc-issuer https://token.actions.githubusercontent.com \
   ghcr.io/kadras-io/package-for-metrics-server | jq
```

You can also verify the SLSA Provenance attestation associated with the image.

```shell
cosign verify-attestation --type slsaprovenance \
   --certificate-identity-regexp https://github.com/slsa-framework \
   --certificate-oidc-issuer https://token.actions.githubusercontent.com \
   ghcr.io/kadras-io/package-for-metrics-server | jq .payload -r | base64 --decode | jq
```
