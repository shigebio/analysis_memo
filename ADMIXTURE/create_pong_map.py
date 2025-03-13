import argparse

def generate_admixture_file(K, R, output_file="admixture_runs.txt"):
    with open(output_file, "w") as f:
        for k in range(1, K + 1):  # K = 1, 2, ..., K
            for r in range(1, R + 1):  # r = 1, 2, ..., R
                line = f"K{k}r{r}\t{k}\t./Admixture-input.{k}_trial{r}.Q\n"
                f.write(line)
    print(f"File '{output_file}' has been created.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Admixture run file.")
    parser.add_argument("-K", type=int, required=True, help="Maximum number of clusters (K)")
    parser.add_argument("-R", type=int, required=True, help="Number of trials (R)")
    parser.add_argument("-o", "--output", type=str, default="admixture_runs.txt",
                        help="Output filename (default: admixture_runs.txt)")

    args = parser.parse_args()
    generate_admixture_file(args.K, args.R, args.output)
