
help:  ## Show help
	@grep -E '^[.a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

clean: ## Clean autogenerated files
	rm -rf dist
	find . -type f -name "*.DS_Store" -ls -delete
	find . | grep -E "(__pycache__|\.pyc|\.pyo)" | xargs rm -rf
	find . | grep -E ".pytest_cache" | xargs rm -rf
	find . | grep -E ".ipynb_checkpoints" | xargs rm -rf

clean-logs: ## Clean logs
	rm -rf logs/**

format: ## Run pre-commit hooks
	pre-commit run -a

install:
	chmod +rwx scripts/install.sh && scripts/install.sh

create-ncs-dataset: ## Runs script that scraps the ncs.io site and creates NCS dataset
	python src/scripts/prepare_audio.py \
		datamodule.audio.preparers.ncs_preparer.download=False \
		datamodule.audio.preparers.ncs_preparer.create=True \
		datamodule.audio.preparers.ncs_preparer.split=True \

prepare-audio: ## Download and prepare datasets with mp3 audio files
	python src/scripts/prepare_audio.py \
		datamodule.audio.preparers.ncs_preparer.download=True \
		datamodule.audio.preparers.gs_mtg_preparer.download=True \
		datamodule.audio.preparers.gs_key_preparer.download=True 

split-audio:
	python src/scripts/prepare_audio.py \
		datamodule.audio.preparers.ncs_preparer.split=True \
		datamodule.audio.preparers.gs_mtg_preparer.split=True \
		datamodule.audio.preparers.gs_key_preparer.split=True 

prepare-ncs-audio: ## Download and prepare NCS dataset
	python src/scripts/prepare_audio.py \
		datamodule.audio.preparers.ncs_preparer.download=True \
		datamodule.audio.preparers.ncs_preparer.split=True \

prepare-gs-mtg-audio: ## Download and prepare GS MTG dataset
	python src/scripts/prepare_audio.py \
		datamodule.audio.preparers.gs_mtg_preparer.download=True \
		datamodule.audio.preparers.gs_mtg_preparer.split=True

prepare-gs-key-audio: ## Download and prepare GS KEY dataset
	python src/scripts/prepare_audio.py \
		datamodule.audio.preparers.gs_key_preparer.download=True \
		datamodule.audio.preparers.gs_key_preparer.split=True

prepare-images: ## Download images with precomputed spectrograms for each dataset
	mkdir -p data/audio/images && python src/scripts/prepare_images.py \
	datamodule.image.download=True

create-spectrograms: ## Create and save spectrogram images from existing audio files in all datasets
	python src/scripts/create_spectrograms.py 

prepare-spectrograms: ## Downloads audio files, creates and saves spectrograms images for all datasets
	python src/scripts/create_spectrograms.py \
		datamodule.audio.preparers.ncs_preparer.download=True \
		datamodule.audio.preparers.ncs_preparer.split=True \
		datamodule.audio.preparers.gs_mtg_preparer.download=True \
		datamodule.audio.preparers.gs_mtg_preparer.split=True \
		datamodule.audio.preparers.gs_key_preparer.download=True \
		datamodule.audio.preparers.gs_key_preparer.split=True

create-tensors: ## Download and prepare datasets with mp3 audio files
	python src/scripts/create_tensors.py \
		datamodule.audio.transform=None

prepare-tensors: ## Download and prepare datasets with mp3 audio files
	python src/scripts/create_tensors.py \
		datamodule.audio.preparers.ncs_preparer.download=True \
		datamodule.audio.preparers.gs_mtg_preparer.download=True \
		datamodule.audio.preparers.gs_key_preparer.download=True \
		datamodule.audio.transform=None

eval: ## Default eval (on song fragments)
	python src/eval.py

eval-full: ## Evaluation the model on full songs
	python src/eval.py full=True

eval-audio: ## Eval the model on audio files
	python src/eval.py datamodule_type='audio'

eval-audio-ncs-only: ## Eval the model on audio files and only NCS dataset
	python src/eval.py datamodule_type='audio' \
		"datamodule/audio/test_datasets=[ncs_test_dataset]"

eval-audio-gs_key-only: ## Eval the model on audio filesand only GS Key dataset
	python src/eval.py datamodule_type='audio' \
		"datamodule/audio/test_datasets=[gs_key_dataset]"

eval-images: ## Eval the model on spectrograms images files
	python src/eval.py datamodule_type='image'

eval-images-ncs-only: ## Eval the model with images and only NCS dataset
	python src/eval.py \
    	"datamodule/image/test_datasets=[ncs_test_dataset]"

eval-images-gs_mtg-only: ## Eval the model with images and only GS Key dataset
	python src/eval.py \
    	"datamodule/image/test_datasets=[gs_key_dataset]"

train: ## Train the model
	python src/train.py

train-from-checkpoint: ## Train the model from checkpoint
	python src/train.py ckpt_path='checkpoints/best.ckpt'

train-audio: ## Train the model with AudioDataModule
	python src/train.py datamodule_type='audio'

train-audio-ncs-only: ## Train the model with audio and only NCS dataset
	python src/train.py \
    	"datamodule/audio/train_datasets=[ncs_train_dataset]"

train-audio-gs_mtg-only: ## Train the model with audio and only GS MTG dataset
	python src/train.py \
    	"datamodule/audio/train_datasets=[gs_mtg_dataset]"

train-images: ## Train the model with ImageDataModule
	python src/train.py datamodule_type='image'

train-images-ncs-only: ## Train the model with images and only NCS dataset
	python src/train.py \
    	"datamodule/image/train_datasets=[ncs_train_dataset]"

train-images-gs_mtg-only: ## Train the model with images and only GS MTG dataset
	python src/train.py \
    	"datamodule/image/train_datasets=[gs_mtg_dataset]"

test-default: ## Test model by running 1 full epoch
	python src/train.py debug=fdr

test-overfit: ## Test model by running 1 train, val and test loop, using only 1 batch
	python src/train.py debug=fdr

test-fdr: ## Test model with overfit on 1 batch
	python src/train.py debug=overfit

test-limit: ## Test model by running train on 1% of data
	python src/train.py debug=limit

experiments-nf: ## Run experiments with different number of feature maps
	scripts/experiments_nf.sh

experiments-hparams: ## Run experiments for hyperparams tuning
	scripts/experiments_nf.sh

experiments-dataset: ## Run experiments with different combinations of datasets
	scripts/experiments_nf.sh


tune-batch-size: ## find optimal batch_size such that doesn't cause out of memory exception
	python src/tune.py ++trainer.auto_scale_batch_size='power'


tune-learning-rate: ## find optimal batch_size such that doesn't cause out of memory exception
	python src/tune.py ++trainer.auto_lr_find=True

debug: ## Enter debugging mode with pdb
	#
	# tips:
	# - use "import pdb; pdb.set_trace()" to set breakpoint
	# - use "h" to print all commands
	# - use "n" to execute the next line
	# - use "c" to run until the breakpoint is hit
	# - use "l" to print src code around current line, "ll" for full function code
	# - docs: https://docs.python.org/3/library/pdb.html
	#
	python -m pdb src/train.py debug=default
