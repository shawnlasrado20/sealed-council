RANK: A > B

A isolates corpus, retrieval, and generation with expert labels plus a gold-evidence swap, then builds a small held-out human eval that scores both evidence recall and answers (currency, completeness, citations, abstention) by intent. That matches the symptom—wrong or outdated replies—without collapsing it to one accuracy number.

B’s five-way taxonomy and retrieval-first eval are cheaper and correctly flag chunking, which A underweights. But B guesses where failures concentrate, delays answer grading, and prescribes larger k and smaller chunks before measuring coverage. Both fix content, then retrieval, then grounded generation, model last; A is stricter about measuring before those knobs and names the real risk: overfitting a set that is not live traffic.
